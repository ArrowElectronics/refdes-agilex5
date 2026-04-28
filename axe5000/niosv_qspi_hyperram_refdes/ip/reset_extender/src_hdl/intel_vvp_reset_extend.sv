/* ##########################################################################
 *
* $Id: $
*
* Module: intel_vvp_reset_extend
*
* Description: extends reset duration
*
* ##########################################################################
*
 * INTEL CONFIDENTIAL
* Copyright 2018 Intel Corporation
*
 * The source code contained or described herein and all documents related
* to the source code ("Material") are owned by Intel Corporation or
* its suppliers or licensors. Title to the Material remains with Intel
* Corporation or its suppliers and licensors. The Material contains trade
* secrets and proprietary and confidential information of Intel or its
* suppliers and licensors. The Material is protected by worldwide copyright
* and trade secret laws and treaty provisions. No part of the Material
* may be used, copied, reproduced, modified, published, uploaded, posted,
* transmitted, distributed, or disclosed in any way without Intel's prior
* express written permission.
*
 * No license under any patent, copyright, trade secret or other intellectual
* property right is granted to or conferred upon you by disclosure or
* delivery of the Materials, either expressly, by implication, inducement,
* estoppel or otherwise. Any license under such intellectual property
* rights must be express and approved by Intel in writing.
* ##########################################################################
*/

module intel_vvp_reset_extend

   (  clk,
      rst_in,
      rst_out,
      rst_out_dup
   );
   
   parameter   RESYNC_RESET_IN   =  1;
   parameter   SYNC_LEN          =  3;   
   parameter   RESET_MIN_LENGTH  =  256;
   
   localparam  LOCAL_ONE_CONST   =  1;
   
   function integer local_log2;
      input [31:0] value;
      begin
         local_log2 = 1;
         while (2**local_log2 < value) begin
            local_log2 = local_log2 + 1;
         end
      end
   endfunction
   
   localparam  COUNT_WIDTH       =  local_log2(RESET_MIN_LENGTH) + 1;
   
   input    wire  clk;
   input    wire  rst_in;
   
   output   wire  rst_out;
   output   wire  rst_out_dup;
   
   reg   [COUNT_WIDTH - 1 : 0]   reset_count;
   
   wire                          rst_internal;
   
   generate
   
      if (RESYNC_RESET_IN > 0) begin
      
         reg   [SYNC_LEN - 1 : 0]   reset_sync;
      
         always @ (posedge clk) begin
            for (int i=0; i<SYNC_LEN; i=i+1) begin
               if (i==0) begin
                  reset_sync[i] <= rst_in;
               end else begin
                  reset_sync[i] <= reset_sync[i-1];
               end
            end
         end
         
         assign rst_internal = reset_sync[SYNC_LEN-1];
      
      end else begin
      
         assign rst_internal = rst_in;
      
      end
   
   endgenerate
   
   always @ (posedge clk) begin
      if (rst_internal) begin
         reset_count <= {1'b1,{COUNT_WIDTH-1{1'b0}}};
      end else begin
         if (reset_count[COUNT_WIDTH-1]) begin
            reset_count <= reset_count + LOCAL_ONE_CONST[COUNT_WIDTH-1:0];
         end
      end
   end
   
   assign rst_out = reset_count[COUNT_WIDTH-1];
   assign rst_out_dup = reset_count[COUNT_WIDTH-1];
   
endmodule
   
   