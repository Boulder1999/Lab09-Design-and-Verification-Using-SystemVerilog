module FD(input clk, INF.FD_inf inf);
import usertype::*;

//===========================================================================
// parameter 
//===========================================================================
EAT_sta cs, ns ;
Action i_action;
Delivery_man_id i_d_id;
Ctm_Info i_ctm_info;
Restaurant_id i_res_id;
food_ID_servings i_food;
res_info res_now,res_last;
D_man_Info d_man_now,d_man_last;
logic flag_complete;
logic flag_id_valid;
logic [9:0] order_food1_temp;
logic [9:0] order_food2_temp;
logic [9:0] order_food3_temp;
//===========================================================================
// logic 
//===========================================================================
always_ff @(posedge clk or negedge inf.rst_n)begin
    if(!inf.rst_n) cs <= IDLE;
    else cs <= ns ;
end
always_comb begin
    ns = cs;
    case(cs)
        IDLE: if(inf.act_valid==1) ns = ACT ;
        ACT:begin
            case(i_action)
            Take:begin
                if(inf.id_valid) ns = START_RDdeliver;
                else begin
                    if(inf.cus_valid) ns = START_RDdeliver ;
                    else ns = cs;
                end
            end
            Deliver: begin
                if(inf.id_valid)ns = START_RDdeliver;
                else ns = cs;
            end
            Order:begin
                if(inf.res_valid) ns = START_RDres ;
                else begin
                    if(inf.food_valid) ns = START_RDres ;
                    else ns = cs;
                end
            end
            Cancel:begin
                if(inf.res_valid)ns = START_RDres ;
                else ns = cs;
            end
            default: ns = cs;
            endcase 
        end 
        START_RDdeliver: ns = RDdeliver;
        START_RDres : ns = RDres;
        START_SAVE_deliver : ns = SAVE_deliver;
        START_SAVE_res : ns = SAVE_res;
        RDdeliver:begin
            case(i_action)
            Take:begin 
                if(inf.C_out_valid) ns = START_RDres;
                else ns = cs;
            end
            Deliver: begin 
                if(inf.C_out_valid) ns = PROCESS1;
                else ns = cs;
            end
            Cancel:begin 
                if(inf.C_out_valid) ns = PROCESS1;
                else ns = cs;
            end
            default: ns = cs;
            endcase
        end
        RDres:begin
            case(i_action)
            Take:begin
                if(inf.C_out_valid) ns = PROCESS1;
                else ns = cs;
            end
            Order:begin
                if(inf.C_out_valid) ns = PROCESS1;
                else ns = cs;
            end
            Cancel:begin
                if(inf.C_out_valid) ns = WAIT_ID;
                else ns = cs;
            end
            default:ns = cs;
            endcase
        end
        WAIT_ID: begin
            if(flag_id_valid) ns = START_RDdeliver ;
            else ns = cs;
        end
        PROCESS1: ns = PROCESS2 ;
        PROCESS2: begin
            if(flag_complete) begin
                case(i_action)
                Take:ns = START_SAVE_deliver ;
                Deliver: ns = START_SAVE_deliver ;
                Order: ns = WAIT_order;
                Cancel: ns = START_SAVE_deliver ;
                endcase
            end
            else  if(i_action == Order) ns = WAIT_order;
            else ns = OUT;
        end 
        WAIT_order : ns = WAIT_order2 ;
        WAIT_order2:begin
            if(flag_complete) ns = START_SAVE_res;
            else ns = OUT;
        end
        OUT: begin
             ns = IDLE;
        end
        SAVE_deliver:begin
            case(i_action)
            Take: if(inf.C_out_valid) ns = START_SAVE_res;
            default : if(inf.C_out_valid) ns = OUT;
            endcase
        end
        SAVE_res:begin
            if(inf.C_out_valid) ns = OUT;
            else ns = cs;
        end
        default:ns = cs;
    endcase
end
// res_now
logic [9:0] sum_ser_food,sum_ser_food2;
always_ff @(posedge clk or negedge inf.rst_n)begin
    if(!inf.rst_n) sum_ser_food<=0;
    else begin
        if(cs == PROCESS1) begin
            sum_ser_food <= res_now.ser_FOOD1 +res_now.ser_FOOD2 +res_now.ser_FOOD3;
        end
    end
end
always_ff @(posedge clk or negedge inf.rst_n)begin
    if(!inf.rst_n) sum_ser_food2<=0;
    else begin
        if(cs == PROCESS2) begin
            sum_ser_food2 <= order_food1_temp +order_food2_temp +order_food3_temp + i_food.d_ser_food;
        end
    end
end
always_ff @(posedge clk or negedge inf.rst_n)begin
    if(!inf.rst_n) order_food1_temp<=0;
    else begin
        if(cs == PROCESS1) begin
            order_food1_temp<= res_now.ser_FOOD1 ;
        end
    end
end
always_ff @(posedge clk or negedge inf.rst_n)begin
    if(!inf.rst_n) order_food2_temp<=0;
    else begin
        if(cs == PROCESS1) begin
            order_food2_temp<= res_now.ser_FOOD2 ;
        end
    end
end
always_ff @(posedge clk or negedge inf.rst_n)begin
    if(!inf.rst_n) order_food3_temp<=0;
    else begin
        if(cs == PROCESS1) begin
            order_food3_temp<= res_now.ser_FOOD3 ;
        end
    end
end
always_ff @(posedge clk or negedge inf.rst_n)begin
    if(!inf.rst_n) res_now<=0;
    else begin
        if( cs == RDres &&  inf.C_out_valid==1) begin
            //d_man_last <= {inf.C_data_r[47:32] , inf.C_data_r[63:48]};
            //d_man_last <= { inf.C_data_r[63:48],inf.C_data_r[47:32] };
            d_man_last.ctm_info1.ctm_status <={inf.C_data_r[39:38]};
            d_man_last.ctm_info1.res_ID <={inf.C_data_r[37:32],inf.C_data_r[47:46]};
            d_man_last.ctm_info1.food_ID <={inf.C_data_r[45:44]};
            d_man_last.ctm_info1.ser_food <={inf.C_data_r[43:40]};

            d_man_last.ctm_info2.ctm_status <={inf.C_data_r[55:54]};
            d_man_last.ctm_info2.res_ID <={inf.C_data_r[53:48],inf.C_data_r[63:62]};
            d_man_last.ctm_info2.food_ID <={inf.C_data_r[61:60]};
            d_man_last.ctm_info2.ser_food <={inf.C_data_r[59:56]};
            res_now <={inf.C_data_r[7:0] , inf.C_data_r[15:8] , inf.C_data_r[23:16] , inf.C_data_r[31:24]};
            
        end
        else if(cs == PROCESS1) begin
            case(i_action)
            Take:begin
                if(d_man_now.ctm_info2.ctm_status==None)begin //deliver no busy
                        case(i_ctm_info.food_ID)
                            FOOD1:begin
                                if(res_now.ser_FOOD1 >=  i_ctm_info.ser_food) res_now.ser_FOOD1 <= res_now.ser_FOOD1 - i_ctm_info.ser_food;
                                else res_now<=res_now;
                            end
                            FOOD2:begin
                                if(res_now.ser_FOOD2 >=  i_ctm_info.ser_food) res_now.ser_FOOD2 <= res_now.ser_FOOD2 -  i_ctm_info.ser_food;
                                else res_now<=res_now;
                            end
                            FOOD3:begin
                                if(res_now.ser_FOOD3 >=  i_ctm_info.ser_food) res_now.ser_FOOD3 <= res_now.ser_FOOD3 -  i_ctm_info.ser_food;
                                else res_now<=res_now;
                            end
                            default:res_now<=res_now;
                        endcase
                end
                else if(d_man_now.ctm_info1.ctm_status==None && d_man_now.ctm_info2.ctm_status!=None)begin
                    case(i_ctm_info.food_ID)
                            FOOD1:begin
                                if(res_now.ser_FOOD1 >=  i_ctm_info.ser_food) res_now.ser_FOOD1 <= res_now.ser_FOOD1 - i_ctm_info.ser_food;
                                else res_now<=res_now;
                            end
                            FOOD2:begin
                                if(res_now.ser_FOOD2 >=  i_ctm_info.ser_food) res_now.ser_FOOD2 <= res_now.ser_FOOD2 -  i_ctm_info.ser_food;
                                else res_now<=res_now;
                            end
                            FOOD3:begin
                                if(res_now.ser_FOOD3 >=  i_ctm_info.ser_food) res_now.ser_FOOD3 <= res_now.ser_FOOD3 -  i_ctm_info.ser_food;
                                else res_now<=res_now;
                            end
                            default:res_now<=res_now;
                        endcase
                end
                else res_now<=res_now;
            end
            /*Order:begin
                if(res_now.limit_num_orders >= sum_ser_food) begin
                    case(i_food.d_food_ID)
                            FOOD1:begin
                                res_now.ser_FOOD1 <= res_now.ser_FOOD1 + i_food.d_ser_food;
                            end
                            FOOD2:begin
                               res_now.ser_FOOD2 <= res_now.ser_FOOD2 + i_food.d_ser_food;
                            end
                            FOOD3:begin
                                res_now.ser_FOOD3 <= res_now.ser_FOOD3 + i_food.d_ser_food;
                            end
                            default:res_now<=res_now;
                        endcase
                end
                else  res_now<=res_now;
            end*/
            default:res_now<=res_now;
            endcase
        end
        else if(ns == WAIT_order2) begin
            case(i_food.d_food_ID)
                FOOD1:begin
                    res_now.ser_FOOD1 <= res_now.ser_FOOD1 + i_food.d_ser_food;
                end
                FOOD2:begin
                    res_now.ser_FOOD2 <= res_now.ser_FOOD2 + i_food.d_ser_food;
                end
                FOOD3:begin
                    res_now.ser_FOOD3 <= res_now.ser_FOOD3 + i_food.d_ser_food;
                end
                default:res_now<=res_now;
            endcase
        end
        else res_now<=res_now;
    end
end
// d_man_now
always_ff @(posedge clk or negedge inf.rst_n)begin
    if(!inf.rst_n) d_man_now<=0;
    else begin
        if(cs == RDdeliver && inf.C_out_valid==1) begin
            
            //d_man_now <={inf.C_data_r[47:32] , inf.C_data_r[63:48]};
            //d_man_now <={ inf.C_data_r[63:48],inf.C_data_r[47:32] };
            d_man_now.ctm_info1.ctm_status <={inf.C_data_r[39:38]};
            d_man_now.ctm_info1.res_ID <={inf.C_data_r[37:32],inf.C_data_r[47:46]};
            d_man_now.ctm_info1.food_ID <={inf.C_data_r[45:44]};
            d_man_now.ctm_info1.ser_food <={inf.C_data_r[43:40]};

            d_man_now.ctm_info2.ctm_status <={inf.C_data_r[55:54]};
            d_man_now.ctm_info2.res_ID <={inf.C_data_r[53:48],inf.C_data_r[63:62]};
            d_man_now.ctm_info2.food_ID <={inf.C_data_r[61:60]};
            d_man_now.ctm_info2.ser_food <={inf.C_data_r[59:56]};

            res_last<={inf.C_data_r[7:0] , inf.C_data_r[15:8] , inf.C_data_r[23:16] , inf.C_data_r[31:24]};
            
            
        end
        else if(cs == PROCESS1)begin
            case(i_action)
            Take:begin
                case(i_ctm_info.food_ID)
                FOOD1:begin
                    if(res_now.ser_FOOD1 >= i_ctm_info.ser_food) begin
                       if(d_man_now.ctm_info1.ctm_status == None)begin
                            //d_man_now.ctm_info1 <= i_ctm_info;
                            if(d_man_now.ctm_info2.ctm_status != None)begin
                                if(i_ctm_info.ctm_status==VIP) begin
                                    if(d_man_now.ctm_info2.ctm_status == VIP) begin
                                        d_man_now.ctm_info1 <=  d_man_now.ctm_info2;
                                        d_man_now.ctm_info2 <= i_ctm_info;
                                    end
                                    else begin
                                        d_man_now.ctm_info1 <= i_ctm_info;
                                        d_man_now.ctm_info2 <=  d_man_now.ctm_info2;
                                    end
                                end
                                else begin
                                    d_man_now.ctm_info1 <=  d_man_now.ctm_info2;
                                    d_man_now.ctm_info2 <= i_ctm_info;
                                end
                            end
                            else d_man_now.ctm_info1 <= i_ctm_info;
                        end
                        else begin
                            if(d_man_now.ctm_info2.ctm_status == None)begin
                                if(i_ctm_info.ctm_status == VIP) begin
                                    if(d_man_now.ctm_info1.ctm_status == VIP) begin
                                        d_man_now.ctm_info2 <= i_ctm_info;
                                    end
                                    else begin//d_man_now.ctm_info1.ctm_status == Normal
                                        d_man_now.ctm_info2 <= d_man_now.ctm_info1;
                                        d_man_now.ctm_info1 <= i_ctm_info;
                                    end
                                end
                                else begin//i_ctm_info.ctm_status == Normal
                                    d_man_now.ctm_info2 <= i_ctm_info;
                                end
                            end
                            else d_man_now <= d_man_now ;
                        end
                    end
                    else d_man_now <= d_man_now ;
                end
                FOOD2:begin
                    if(res_now.ser_FOOD2 >= i_ctm_info.ser_food) begin
                        if(d_man_now.ctm_info1.ctm_status == None)begin
                            //d_man_now.ctm_info1 <= i_ctm_info;
                            if(d_man_now.ctm_info2.ctm_status != None)begin
                                if(i_ctm_info.ctm_status==VIP) begin
                                    if(d_man_now.ctm_info2.ctm_status == VIP) begin
                                        d_man_now.ctm_info1 <=  d_man_now.ctm_info2;
                                        d_man_now.ctm_info2 <= i_ctm_info;
                                    end
                                    else begin
                                        d_man_now.ctm_info1 <= i_ctm_info;
                                        d_man_now.ctm_info2 <=  d_man_now.ctm_info2;
                                    end
                                end
                                else begin
                                    d_man_now.ctm_info1 <=  d_man_now.ctm_info2;
                                    d_man_now.ctm_info2 <= i_ctm_info;
                                end
                            end
                            else d_man_now.ctm_info1 <= i_ctm_info;
                        end
                        else begin
                            if(d_man_now.ctm_info2.ctm_status == None)begin
                                if(i_ctm_info.ctm_status == VIP) begin
                                    if(d_man_now.ctm_info1.ctm_status == VIP) begin
                                        d_man_now.ctm_info2 <= i_ctm_info;
                                    end
                                    else begin//d_man_now.ctm_info1.ctm_status == Normal
                                        d_man_now.ctm_info2 <= d_man_now.ctm_info1;
                                        d_man_now.ctm_info1 <= i_ctm_info;
                                    end
                                end
                                else begin//i_ctm_info.ctm_status == Normal
                                    d_man_now.ctm_info2 <= i_ctm_info;
                                end
                            end
                            else d_man_now <= d_man_now ;
                        end
                    end
                    else d_man_now <= d_man_now ;
                end
                FOOD3:begin
                    if(res_now.ser_FOOD3 >= i_ctm_info.ser_food) begin
                        if(d_man_now.ctm_info1.ctm_status == None)begin
                            //d_man_now.ctm_info1 <= i_ctm_info;
                            if(d_man_now.ctm_info2.ctm_status != None)begin
                                if(i_ctm_info.ctm_status==VIP) begin
                                    if(d_man_now.ctm_info2.ctm_status == VIP) begin
                                        d_man_now.ctm_info1 <=  d_man_now.ctm_info2;
                                        d_man_now.ctm_info2 <= i_ctm_info;
                                    end
                                    else begin
                                        d_man_now.ctm_info1 <= i_ctm_info;
                                        d_man_now.ctm_info2 <=  d_man_now.ctm_info2;
                                    end
                                end
                                else begin
                                    d_man_now.ctm_info1 <=  d_man_now.ctm_info2;
                                    d_man_now.ctm_info2 <= i_ctm_info;
                                end
                            end
                            else d_man_now.ctm_info1 <= i_ctm_info;
                        end
                        else begin
                            if(d_man_now.ctm_info2.ctm_status == None)begin
                                if(i_ctm_info.ctm_status == VIP) begin
                                    if(d_man_now.ctm_info1.ctm_status == VIP) begin
                                        d_man_now.ctm_info2 <= i_ctm_info;
                                    end
                                    else begin//d_man_now.ctm_info1.ctm_status == Normal
                                        d_man_now.ctm_info2 <= d_man_now.ctm_info1;
                                        d_man_now.ctm_info1 <= i_ctm_info;
                                    end
                                end
                                else begin//i_ctm_info.ctm_status == Normal
                                    d_man_now.ctm_info2 <= i_ctm_info;
                                end
                            end
                            else d_man_now <= d_man_now ;
                        end
                    end
                    else d_man_now <= d_man_now ;
                end
                default:d_man_now <= d_man_now ;
                endcase
            end
            Deliver:begin
                if(d_man_now.ctm_info1.ctm_status != None) begin
                    if(d_man_now.ctm_info2.ctm_status == VIP) begin
                        if(d_man_now.ctm_info1.ctm_status == VIP) begin
                            d_man_now.ctm_info1 <= d_man_now.ctm_info2;
                            d_man_now.ctm_info2 <= 0;
                        end
                        else begin
                            d_man_now.ctm_info1<=d_man_now.ctm_info1;
                            d_man_now.ctm_info2 <= 0;
                        end
                    end
                    else begin
                        d_man_now.ctm_info1 <= d_man_now.ctm_info2;
                        d_man_now.ctm_info2 <= 0;
                    end
                end
                else if(d_man_now.ctm_info1.ctm_status == None && d_man_now.ctm_info2.ctm_status != None )begin
                    d_man_now.ctm_info2 <= 0;
                end
                else d_man_now <= d_man_now ;
            end
            Cancel:begin
                if(d_man_now.ctm_info1.ctm_status != None && d_man_now.ctm_info2.ctm_status == None)begin
                    if(d_man_now.ctm_info1.res_ID == i_res_id) begin
                        if(d_man_now.ctm_info1.food_ID == i_food.d_food_ID) begin
                            d_man_now <= 0;
                        end
                        else d_man_now <= d_man_now ;
                    end
                    else d_man_now <= d_man_now ;
                end
                else if(d_man_now.ctm_info1.ctm_status != None && d_man_now.ctm_info2.ctm_status != None)begin
                    if(d_man_now.ctm_info1.res_ID == i_res_id && d_man_now.ctm_info2.res_ID == i_res_id) begin//all cancel
                        if(d_man_now.ctm_info1.food_ID == i_food.d_food_ID && d_man_now.ctm_info2.food_ID == i_food.d_food_ID) begin
                            d_man_now <= 0;
                        end
                        else begin
                            if(d_man_now.ctm_info1.food_ID == i_food.d_food_ID) begin
                                d_man_now.ctm_info1 <= d_man_now.ctm_info2;
                                d_man_now.ctm_info2 <= 0;
                            end
                            else if(d_man_now.ctm_info2.food_ID == i_food.d_food_ID) begin
                                d_man_now.ctm_info1 <= d_man_now.ctm_info1;
                                d_man_now.ctm_info2 <= 0;
                            end
                            else d_man_now <= d_man_now ;
                        end
                    end
                    else begin
                        if(d_man_now.ctm_info1.res_ID == i_res_id ) begin// ctm1 cancel
                            if(d_man_now.ctm_info1.food_ID == i_food.d_food_ID) begin
                                d_man_now.ctm_info1 <= d_man_now.ctm_info2;
                                d_man_now.ctm_info2 <= 0;
                            end
                            else d_man_now <= d_man_now ;
                        end
                        else if(d_man_now.ctm_info2.res_ID == i_res_id) begin// ctm2 cancel
                            if(d_man_now.ctm_info2.food_ID == i_food.d_food_ID) begin
                                d_man_now.ctm_info2 <= 0;
                            end
                            else d_man_now <= d_man_now ;
                        end
                        else d_man_now <= d_man_now ;
                    end
                end
                else d_man_now <= d_man_now ;
            end
            default : d_man_now <= d_man_now ;
            endcase
        end
    end
end
//out
always_ff @(posedge clk or negedge inf.rst_n)begin
    if(!inf.rst_n) inf.out_valid<=0;
    else if(ns == OUT) inf.out_valid<=1;
    else inf.out_valid<=0;
end
always_ff @(posedge clk or negedge inf.rst_n)begin
    if(!inf.rst_n) inf.out_info<=0;
    else begin
        if(ns == OUT) begin
            if(flag_complete) begin
                case(i_action)
                Take:inf.out_info<={d_man_now , res_now};
                Deliver:inf.out_info<={d_man_now ,32'd0};
                Order:inf.out_info<={32'd0 , res_now};
                Cancel:inf.out_info<={d_man_now ,32'd0};
                default:inf.out_info<=0;
                endcase
            end
            else inf.out_info<=0;
        end
        else inf.out_info <=0;
    end
end
//error

always_ff @(posedge clk or negedge inf.rst_n)begin
    if(!inf.rst_n) inf.err_msg<=0;
    else begin
        if(cs == PROCESS1) begin
            case(i_action)
            Take:begin
                case(i_ctm_info.food_ID)
                FOOD1:begin
                    if(d_man_now.ctm_info1.ctm_status != None && d_man_now.ctm_info2.ctm_status != None) inf.err_msg<=D_man_busy;
                    else begin
                        if(res_now.ser_FOOD1 < i_ctm_info.ser_food) inf.err_msg<= No_Food;
                        else inf.err_msg <= No_Err;
                    end
                end
                FOOD2:begin
                    if(d_man_now.ctm_info1.ctm_status != None && d_man_now.ctm_info2.ctm_status != None) inf.err_msg<=D_man_busy;
                        else begin
                            if(res_now.ser_FOOD2 < i_ctm_info.ser_food) inf.err_msg<= No_Food;
                            else inf.err_msg <= No_Err;
                        end
                end
                FOOD3:begin
                    if(d_man_now.ctm_info1.ctm_status != None && d_man_now.ctm_info2.ctm_status != None) inf.err_msg<=D_man_busy;
                        else begin
                            if(res_now.ser_FOOD3 < i_ctm_info.ser_food) inf.err_msg<= No_Food;
                            else inf.err_msg <= No_Err;
                        end
                end
                default:inf.err_msg <= No_Err;
                endcase
            end
            Deliver:begin
                if(d_man_now.ctm_info1.ctm_status == None && d_man_now.ctm_info2.ctm_status == None) inf.err_msg <= No_customers;
                else inf.err_msg <= No_Err;
            end
            Order:begin
                if(res_now.limit_num_orders <= sum_ser_food)begin
                    inf.err_msg <= Res_busy;
                end
                else inf.err_msg <= No_Err;
            end
            Cancel:begin
                if(d_man_now.ctm_info1.ctm_status == None && d_man_now.ctm_info2.ctm_status == None) inf.err_msg <= Wrong_cancel;
                else begin
                    if(d_man_now.ctm_info1.ctm_status != None && d_man_now.ctm_info2.ctm_status == None) begin
                        if(i_res_id == d_man_now.ctm_info1.res_ID ) begin
                            if(i_food.d_food_ID != d_man_now.ctm_info1.food_ID ) inf.err_msg <= Wrong_food_ID;
                            else inf.err_msg <= No_Err;
                        end
                        else begin
                             inf.err_msg <= Wrong_res_ID;
                        end
                    end
                    else if(d_man_now.ctm_info2.ctm_status != None) begin
                        if(i_res_id == d_man_now.ctm_info1.res_ID && i_res_id == d_man_now.ctm_info2.res_ID)begin
                            if(i_food.d_food_ID == d_man_now.ctm_info1.food_ID && i_food.d_food_ID == d_man_now.ctm_info2.food_ID)begin
                                inf.err_msg <= No_Err;
                            end
                            else begin
                                if( i_food.d_food_ID == d_man_now.ctm_info1.food_ID) inf.err_msg <= No_Err;
                                else if( i_food.d_food_ID == d_man_now.ctm_info2.food_ID) inf.err_msg <= No_Err;
                                else inf.err_msg  <= Wrong_food_ID;
                            end
                        end
                        else begin
                            if(i_res_id == d_man_now.ctm_info1.res_ID  ) begin
                                if( i_food.d_food_ID == d_man_now.ctm_info1.food_ID) inf.err_msg <= No_Err;
                                else inf.err_msg <= Wrong_food_ID;
                            end
                            else if(i_res_id == d_man_now.ctm_info2.res_ID )begin
                                if( i_food.d_food_ID == d_man_now.ctm_info2.food_ID) inf.err_msg <= No_Err;
                                else inf.err_msg <= Wrong_food_ID;
                            end
                            else begin
                                inf.err_msg <= Wrong_res_ID;
                            end
                        end
                    end
                end
            end
            default: inf.err_msg <= No_Err;
            endcase
        end
        else if(ns == WAIT_order2) begin
            if(i_action == Order)  begin
                if(res_now.limit_num_orders < sum_ser_food2) inf.err_msg<=Res_busy;
                else inf.err_msg<=No_Err;
            end
        end
    end
end
always_ff @(posedge clk or negedge inf.rst_n)begin
    if(!inf.rst_n) inf.complete<=0;
    else begin
        if(ns == OUT) begin
            inf.complete<=flag_complete;
        end
        else if(ns == IDLE) inf.complete<=0;
    end
end
always_ff @(posedge clk or negedge inf.rst_n)begin
    if(!inf.rst_n) flag_complete<=0;
    else begin
        if(ns == IDLE) flag_complete<=0;
        else if(cs == PROCESS1 ) begin
            case(i_action)
            Take:begin
                case(i_ctm_info.food_ID)
                FOOD1:begin
                    if(res_now.ser_FOOD1 < i_ctm_info.ser_food) flag_complete<=0;
                    else begin
                        if(d_man_now.ctm_info1.ctm_status != None && d_man_now.ctm_info2.ctm_status != None) flag_complete<=0;
                        else flag_complete<=1;
                    end
                end
                FOOD2:begin
                    if(res_now.ser_FOOD2 < i_ctm_info.ser_food) flag_complete<=0;
                    else begin
                        if(d_man_now.ctm_info1.ctm_status != None && d_man_now.ctm_info2.ctm_status != None) flag_complete<=0;
                        else flag_complete<=1;
                    end
                end
                FOOD3:begin
                    if(res_now.ser_FOOD3 < i_ctm_info.ser_food) flag_complete<=0;
                    else begin
                        if(d_man_now.ctm_info1.ctm_status != None && d_man_now.ctm_info2.ctm_status != None) flag_complete<=0;
                        else flag_complete<=1;
                    end
                end
                default:flag_complete<=1;
                endcase
            end
            Deliver:begin
                if(d_man_now.ctm_info1.ctm_status == None && d_man_now.ctm_info2.ctm_status == None) flag_complete<=0;
                else flag_complete<=1;
            end
            Order:begin
                if(res_now.limit_num_orders <= sum_ser_food )begin
                    flag_complete<=0;
                end
                else flag_complete<=1;
            end
            Cancel:begin
                if(d_man_now.ctm_info1.ctm_status == None && d_man_now.ctm_info2.ctm_status == None) flag_complete<=0;
                else begin
                    if(d_man_now.ctm_info1.ctm_status != None && d_man_now.ctm_info2.ctm_status == None) begin
                        if(i_res_id == d_man_now.ctm_info1.res_ID ) begin
                            if(i_food.d_food_ID != d_man_now.ctm_info1.food_ID ) flag_complete<=0;
                            else flag_complete<=1;
                        end
                        else begin
                             flag_complete<=0;
                        end
                    end
                    else if(d_man_now.ctm_info2.ctm_status != None) begin
                        if(i_res_id == d_man_now.ctm_info1.res_ID && i_res_id == d_man_now.ctm_info2.res_ID)begin
                            if(i_food.d_food_ID == d_man_now.ctm_info1.food_ID && i_food.d_food_ID == d_man_now.ctm_info2.food_ID)begin
                                flag_complete<=1;
                            end
                            else begin
                                if( i_food.d_food_ID == d_man_now.ctm_info1.food_ID) flag_complete<=1;
                                else if( i_food.d_food_ID == d_man_now.ctm_info2.food_ID) flag_complete<=1;
                                else flag_complete<=0;
                            end
                        end
                        else begin
                            if(i_res_id == d_man_now.ctm_info1.res_ID  ) begin
                                if( i_food.d_food_ID == d_man_now.ctm_info1.food_ID) flag_complete<=1;
                                else flag_complete<=0;
                            end
                            else if(i_res_id == d_man_now.ctm_info2.res_ID )begin
                                if( i_food.d_food_ID == d_man_now.ctm_info2.food_ID) flag_complete<=1;
                                else flag_complete<=0;
                            end
                            else begin
                                flag_complete<=0;
                            end
                        end
                    end
                end
            end
            default: flag_complete<=1;
            endcase
        end
        else if(ns == WAIT_order2) begin
            if(i_action == Order)  begin
                if(res_now.limit_num_orders < sum_ser_food2) flag_complete<=0;
                else flag_complete<=1;
            end
        end
    end
end

///input
always_ff @(posedge clk or negedge inf.rst_n)begin
    if(!inf.rst_n) i_action<=No_action;
    else if(inf.act_valid) i_action <= inf.D.d_act[0];
end

always_ff @(posedge clk or negedge inf.rst_n)begin
    if(!inf.rst_n) i_d_id<=0;
    else if(inf.id_valid) i_d_id <= inf.D.d_id[0];
end

always_ff @(posedge clk or negedge inf.rst_n)begin
    if(!inf.rst_n) flag_id_valid<=0;
    else begin
        if(ns == IDLE) flag_id_valid<=0;
        else if(inf.id_valid) flag_id_valid<=1;
    end
end
always_ff @(posedge clk or negedge inf.rst_n)begin
    if(!inf.rst_n) i_ctm_info<=0;
    else if(inf.cus_valid) i_ctm_info <= inf.D.d_ctm_info[0];
end

always_ff @(posedge clk or negedge inf.rst_n)begin
    if(!inf.rst_n) i_res_id<=0;
    else if(inf.res_valid) i_res_id <= inf.D.d_res_id[0];
end

always_ff @(posedge clk or negedge inf.rst_n)begin
    if(!inf.rst_n) i_food<=0;
    else if(inf.food_valid) i_food <= inf.D.d_food_ID_ser[0];
end
// FD Bridge
always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n) 	inf.C_addr <= 0 ;
    else if(ns == IDLE) inf.C_addr <= 0 ;
	else begin
        case(i_action)
        Take:begin
            case(ns)
                RDdeliver:	inf.C_addr <= i_d_id ;
                RDres:		inf.C_addr <= i_ctm_info.res_ID ;
                SAVE_deliver: inf.C_addr <= i_d_id;
                SAVE_res: inf.C_addr <= i_ctm_info.res_ID ;
            endcase
        end
        Deliver:begin
            case(ns)
                RDdeliver:	inf.C_addr <= i_d_id ;
                SAVE_deliver: inf.C_addr <= i_d_id ;
            endcase
        end
        Order:begin
            case(ns)
                RDres:		inf.C_addr <=  i_res_id ;
                SAVE_res: inf.C_addr <= i_res_id ;
            endcase
        end
        Cancel:begin
            case(ns)
                RDdeliver:	inf.C_addr <= i_d_id ;
                RDres:		inf.C_addr <= i_res_id ;
                SAVE_deliver: inf.C_addr <= i_d_id ;
                SAVE_res: inf.C_addr <= i_res_id ;
		    endcase
        end
        endcase
	end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n)		inf.C_data_w <= 0 ;
    else if(ns == IDLE ) inf.C_data_w <= 0 ;
	else begin
        case(i_action)
        Take:begin
            if(i_d_id == i_ctm_info.res_ID) begin
                case(ns)
                    SAVE_deliver:begin
                        inf.C_data_w [31:0] <={res_now[7:0],res_now[15:8],res_now[23:16],res_now[31:24]};
                        inf.C_data_w [39:38]<= {d_man_now.ctm_info1.ctm_status} ;
                        inf.C_data_w [37:32]<={d_man_now.ctm_info1.res_ID[7:2]};
                        inf.C_data_w [47:46]<={d_man_now.ctm_info1.res_ID[1:0]};
                        inf.C_data_w [45:44]<={d_man_now.ctm_info1.food_ID};
                        inf.C_data_w [43:40]<={d_man_now.ctm_info1.ser_food };

                        inf.C_data_w [55:54]<= {d_man_now.ctm_info2.ctm_status} ;
                        inf.C_data_w [53:48]<={d_man_now.ctm_info2.res_ID[7:2]};
                        inf.C_data_w [63:62]<={d_man_now.ctm_info2.res_ID[1:0]};
                        inf.C_data_w [61:60]<={d_man_now.ctm_info2.food_ID};
                        inf.C_data_w [59:56]<={d_man_now.ctm_info2.ser_food };
                    end
                    SAVE_res:begin
                        inf.C_data_w [31:0] <={res_now[7:0],res_now[15:8],res_now[23:16],res_now[31:24]};
                        inf.C_data_w [39:38]<= {d_man_now.ctm_info1.ctm_status} ;
                        inf.C_data_w [37:32]<={d_man_now.ctm_info1.res_ID[7:2]};
                        inf.C_data_w [47:46]<={d_man_now.ctm_info1.res_ID[1:0]};
                        inf.C_data_w [45:44]<={d_man_now.ctm_info1.food_ID};
                        inf.C_data_w [43:40]<={d_man_now.ctm_info1.ser_food };

                        inf.C_data_w [55:54]<= {d_man_now.ctm_info2.ctm_status} ;
                        inf.C_data_w [53:48]<={d_man_now.ctm_info2.res_ID[7:2]};
                        inf.C_data_w [63:62]<={d_man_now.ctm_info2.res_ID[1:0]};
                        inf.C_data_w [61:60]<={d_man_now.ctm_info2.food_ID};
                        inf.C_data_w [59:56]<={d_man_now.ctm_info2.ser_food };
                    end
                endcase
            end
            else begin
                case(ns)
                    SAVE_deliver:begin
                        //inf.C_data_w <= {d_man_now.ctm_info1,d_man_now.ctm_info2,res_last[7:0],res_last[15:8],res_last[23:16],res_last[31:24]} ;
                        inf.C_data_w [31:0] <={res_last[7:0],res_last[15:8],res_last[23:16],res_last[31:24]};
                        inf.C_data_w [39:38]<= {d_man_now.ctm_info1.ctm_status} ;
                        inf.C_data_w [37:32]<={d_man_now.ctm_info1.res_ID[7:2]};
                        inf.C_data_w [47:46]<={d_man_now.ctm_info1.res_ID[1:0]};
                        inf.C_data_w [45:44]<={d_man_now.ctm_info1.food_ID};
                        inf.C_data_w [43:40]<={d_man_now.ctm_info1.ser_food };

                        inf.C_data_w [55:54]<= {d_man_now.ctm_info2.ctm_status} ;
                        inf.C_data_w [53:48]<={d_man_now.ctm_info2.res_ID[7:2]};
                        inf.C_data_w [63:62]<={d_man_now.ctm_info2.res_ID[1:0]};
                        inf.C_data_w [61:60]<={d_man_now.ctm_info2.food_ID};
                        inf.C_data_w [59:56]<={d_man_now.ctm_info2.ser_food };
                    end
                    SAVE_res:begin
                        //inf.C_data_w <= {d_man_last.ctm_info1,d_man_last.ctm_info2,res_now[7:0],res_now[15:8],res_now[23:16],res_now[31:24]} ;
                        inf.C_data_w [31:0] <={res_now[7:0],res_now[15:8],res_now[23:16],res_now[31:24]};
                        inf.C_data_w [39:38]<= {d_man_last.ctm_info1.ctm_status} ;
                        inf.C_data_w [37:32]<={d_man_last.ctm_info1.res_ID[7:2]};
                        inf.C_data_w [47:46]<={d_man_last.ctm_info1.res_ID[1:0]};
                        inf.C_data_w [45:44]<={d_man_last.ctm_info1.food_ID};
                        inf.C_data_w [43:40]<={d_man_last.ctm_info1.ser_food };

                        inf.C_data_w [55:54]<= {d_man_last.ctm_info2.ctm_status} ;
                        inf.C_data_w [53:48]<={d_man_last.ctm_info2.res_ID[7:2]};
                        inf.C_data_w [63:62]<={d_man_last.ctm_info2.res_ID[1:0]};
                        inf.C_data_w [61:60]<={d_man_last.ctm_info2.food_ID};
                        inf.C_data_w [59:56]<={d_man_last.ctm_info2.ser_food };
                    end
                endcase
            end
        end
        default:begin
            case(ns)
                    SAVE_deliver:begin
                        //inf.C_data_w <= {d_man_now.ctm_info1,d_man_now.ctm_info2,res_last[7:0],res_last[15:8],res_last[23:16],res_last[31:24]} ;
                        inf.C_data_w [31:0] <={res_last[7:0],res_last[15:8],res_last[23:16],res_last[31:24]};
                        inf.C_data_w [39:38]<= {d_man_now.ctm_info1.ctm_status} ;
                        inf.C_data_w [37:32]<={d_man_now.ctm_info1.res_ID[7:2]};
                        inf.C_data_w [47:46]<={d_man_now.ctm_info1.res_ID[1:0]};
                        inf.C_data_w [45:44]<={d_man_now.ctm_info1.food_ID};
                        inf.C_data_w [43:40]<={d_man_now.ctm_info1.ser_food };

                        inf.C_data_w [55:54]<= {d_man_now.ctm_info2.ctm_status} ;
                        inf.C_data_w [53:48]<={d_man_now.ctm_info2.res_ID[7:2]};
                        inf.C_data_w [63:62]<={d_man_now.ctm_info2.res_ID[1:0]};
                        inf.C_data_w [61:60]<={d_man_now.ctm_info2.food_ID};
                        inf.C_data_w [59:56]<={d_man_now.ctm_info2.ser_food };
                    end
                    SAVE_res:begin
                        //inf.C_data_w <= {d_man_last.ctm_info1,d_man_last.ctm_info2,res_now[7:0],res_now[15:8],res_now[23:16],res_now[31:24]} ;
                        inf.C_data_w [31:0] <={res_now[7:0],res_now[15:8],res_now[23:16],res_now[31:24]};
                        inf.C_data_w [39:38]<= {d_man_last.ctm_info1.ctm_status} ;
                        inf.C_data_w [37:32]<={d_man_last.ctm_info1.res_ID[7:2]};
                        inf.C_data_w [47:46]<={d_man_last.ctm_info1.res_ID[1:0]};
                        inf.C_data_w [45:44]<={d_man_last.ctm_info1.food_ID};
                        inf.C_data_w [43:40]<={d_man_last.ctm_info1.ser_food };

                        inf.C_data_w [55:54]<= {d_man_last.ctm_info2.ctm_status} ;
                        inf.C_data_w [53:48]<={d_man_last.ctm_info2.res_ID[7:2]};
                        inf.C_data_w [63:62]<={d_man_last.ctm_info2.res_ID[1:0]};
                        inf.C_data_w [61:60]<={d_man_last.ctm_info2.food_ID};
                        inf.C_data_w [59:56]<={d_man_last.ctm_info2.ser_food };
                    end
                endcase
        end
        endcase
       
        end
end
always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n)		inf.C_in_valid <= 0 ;
	else begin
        case(cs)
            START_RDdeliver:	    inf.C_in_valid <= 1 ;
            START_RDres: 	        inf.C_in_valid <= 1 ;
            START_SAVE_deliver:	inf.C_in_valid <= 1 ;
            START_SAVE_res:       inf.C_in_valid <= 1 ;
            default:		inf.C_in_valid <= 0 ;
        endcase 
		end
end
always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n) 	inf.C_r_wb <= 0 ;
	else begin
		case(ns)
            IDLE:       inf.C_r_wb <= 0 ;
			//RDdeliver:	inf.C_r_wb <= MODE_READ ;
			//RDres:  	inf.C_r_wb <= MODE_READ ;	
            //SAVE_deliver:	inf.C_r_wb <= MODE_WRITE ;
            //SAVE_res:       inf.C_r_wb <= MODE_WRITE ;
            START_RDdeliver:	    inf.C_r_wb <= MODE_READ ;
            START_RDres: 	        inf.C_r_wb <= MODE_READ ;
            START_SAVE_deliver:	inf.C_r_wb <= MODE_WRITE ;
            START_SAVE_res:      inf.C_r_wb <= MODE_WRITE ;
		endcase 
	end
end
endmodule