`timescale 1ns / 1ps

module L1D_Cache(
        input wire [31:0] input_address,  
        input wire CLK, 
        input wire READY,  
        output reg VALID, 
        output reg [31:0] DATA_L1,  
        input wire [31:0] DATA_MEM,  
        input wire LOAD,   
        inout wire STORE,
        output reg [31:0] data,  
        output reg [3:0] ACK_DATA_L1,
        input wire [3:0] ACK_DATA_MEM,

        input wire RESET_ACK,
        
        output reg ACK_ADDR_L1,
        input wire ACK_ADDR_MEM
        
        
    );
    
    parameter OFFSET_BITS = 3;
    parameter INDEX_BITS = 4;
    parameter TAG_BITS = 32 - OFFSET_BITS - INDEX_BITS;
    parameter WAYS = 4;
    parameter WORDS_PER_LINE = 8;
    parameter SETS = 16;
    
    
    
    wire [TAG_BITS-1:0] tag = input_address[31:OFFSET_BITS+INDEX_BITS];
    wire [INDEX_BITS-1:0] index = input_address[OFFSET_BITS+INDEX_BITS-1:OFFSET_BITS];
    wire [OFFSET_BITS-1:0] offset = input_address[OFFSET_BITS-1:0];
    
    reg CACHE_HIT = 0;
    reg cache_full = 0;
    
    reg [31:0] cache_data[0:SETS-1][0:WAYS-1][0:WORDS_PER_LINE-1];
    reg [TAG_BITS-1:0] cache_tags[0:SETS-1][0:WAYS-1];
    reg [7:0] valid_bits [0:SETS-1][0:WAYS-1];
    
    initial begin
        $readmemh("cache_data.mem", cache_data);
        $readmemh("cache_tags.mem", cache_tags);
        $readmemh("valid_bits.mem", valid_bits);
    end

  
    reg [31:0] fetched_data_from_mem [0:WORDS_PER_LINE-1];
    reg [3:0] word_fetched = 0;
    
    reg [1:0] fifo_counter[0:SETS-1];
    reg [1:0] block_age[0:SETS-1][0:WAYS-1];
    
   
   
    integer i;
    integer j;
    integer way;
    
    reg address_sent = 1'b0;
    
    
    initial begin
        ACK_ADDR_L1 = 1'b0;
       VALID = 1'b0;
        ACK_DATA_L1 <= 4'b1111;
        
        for (i = 0; i < SETS; i = i + 1) begin
            fifo_counter[i] = 2'b0; 
            for (j = 0; j < SETS; j = j + 1) begin
                block_age[i][j] = 2'b0;
            end 
        end
    end
    
    
    reg [1:0] replace_way;
    
    

    always @(posedge CLK) begin 
        // LOAD operation received initially
       
        if (LOAD && !VALID) begin 
            CACHE_HIT <= 1'b0; 
            

            for (way = 0; way < WAYS; way=way+1) begin
                if (cache_tags[index][way] == tag && valid_bits[index][way]) begin
                    
                    data <= cache_data[index][way][offset];
                    CACHE_HIT <= 1'b1;
                    if (CACHE_HIT) begin end
                end
            end
            if (!CACHE_HIT) begin
                VALID <= 1'b1;
            end
        end
        
        // Load Operation: Connection Handshake done -> Here address is sent
        else if (LOAD && VALID && READY && !address_sent) begin
            DATA_L1 <= input_address;
            ACK_ADDR_L1 <= 1'b1;
            address_sent = 1'b1;
        end
        
        // Load Operation: Address has been received by the memory and word_to_be_fetched has been sent by mem
        else if (LOAD && VALID && READY && address_sent && (ACK_ADDR_MEM || word_fetched != 0) && ACK_DATA_MEM == word_fetched) begin
            ACK_ADDR_L1 <= 1'b0;
            fetched_data_from_mem[word_fetched] = DATA_MEM;
            $display("THIS is the word fetched %h", DATA_MEM);
            ACK_DATA_L1 <= word_fetched;
            
            // Load has been completed from L1 Cache side
            if (word_fetched == 4'b0111) begin
                word_fetched <= 0;
                replace_way <= 0;
                cache_full = 1'b1;
                for (way = 0; way < WAYS; way=way+1) begin
                    if (!valid_bits[index][way]) begin
                        replace_way <= way;
                        cache_full <= 1'b0;
                    end
                end
                if (cache_full) begin
                    for (way = 0; way < WAYS; way=way+1) begin
                        if (block_age[index][way] < block_age[index][replace_way]) begin
                            replace_way <= way;
                        end
                    end
                end
            
                for (i = 0; i <= word_fetched; i = i + 1) begin
                    cache_data[index][replace_way][i] = fetched_data_from_mem[i];
                end
                valid_bits[index][replace_way] <= 1'b1;
                cache_tags[index][replace_way] <= tag;
                block_age[index][replace_way] <= fifo_counter[index];
                fifo_counter[index] <= fifo_counter[index] + 1'b1;
                
                data <= fetched_data_from_mem[offset];
                VALID <= 1'b0;
           end

           word_fetched <= word_fetched + 1'b1;
        end

        else if (RESET_ACK) begin 
            ACK_DATA_L1 <= 4'b1111;
            
    
        end
        
        
        
        
    end

    
   
    
    
    
endmodule