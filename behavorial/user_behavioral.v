module user_behavioral (
    input clk,
    input rst,
    input setup_done,
    input [2:0] coin,
    input [2:0] selezione,
    input conferma,
    input annulla,

    // Dati provenienti dal setup
    input [5:0] qt_p1, qt_p2, qt_p3, qt_p4,
    input [5:0] price_p1, price_p2, price_p3, price_p4,
    input [5:0] init_stock_01, init_stock_02, init_stock_05, init_stock_10, // Stock di monete per il calcolo del resto

    // Segnali di uscita
    output reg prodotto1, prodotto2, prodotto3, prodotto4,
    output reg [5:0] credito,
    output reg [1:0] errore,
    output reg [5:0] resto,
    output reg [9:0] disponibile,
    
    // Registri per tenere traccia delle monete erogate come resto
    output reg [5:0] coin_01, coin_02, coin_05, coin_10 
);

    // Definizione degli stati
    localparam IDLE         = 3'b000;
    localparam ACC_CREDIT   = 3'b001;
    localparam SEL_PROD     = 3'b010;
    localparam CHECK_AV     = 3'b011;
    localparam DISPENSE     = 3'b100;
    localparam ERROR        = 3'b101;

    reg [2:0] state;
    reg [2:0] selected_product;
    reg [5:0] current_price;
    reg [5:0] current_qt;

    // Registri per il cambio dello stock di monete, inizializzati con i valori provenienti dal setup
    reg [5:0] stock_01, stock_02, stock_05, stock_10;

    // Logica di funzionamento delle monete
    function [5:0] coin_value(input [2:0] c);
        case (c)
            3'b100 : coin_value = 6'd1;   // 0.10€
            3'b101 : coin_value = 6'd2;   // 0.20€
            3'b110 : coin_value = 6'd5;   // 0.50€
            3'b111 : coin_value = 6'd10;  // 1.00€
            default: coin_value = 6'd0;
        endcase        
    endfunction

    // Task per il calcolo del resto in modo greedy
    task calcolo_greedy;
        input [5:0] amount;
        reg [5:0] remaining;
        begin
            remaining = amount;

            if (remaining >= 10 && stock_10 > 0) begin
                coin_10 = ((remaining / 10) <= stock_10) ? (remaining / 10) : stock_10;
                remaining = remaining - (coin_10 * 10);
            end else coin_10 = 0;

            if (remaining >= 5 && stock_05 > 0) begin
                coin_05 = ((remaining / 5) <= stock_05) ? (remaining / 5) : stock_05;
                remaining = remaining - (coin_05 * 5);
            end else coin_05 = 0;

            if (remaining >= 2 && stock_02 > 0) begin
                coin_02 = ((remaining / 2) <= stock_02) ? (remaining / 2) : stock_02;
                remaining = remaining - (coin_02 * 2);
            end else coin_02 = 0;

            if (remaining >= 1 && stock_01 > 0) begin
                coin_01 = ((remaining / 1) <= stock_01) ? (remaining / 1) : stock_01;
                remaining = remaining - (coin_01 * 1);
            end else coin_01 = 0;
                
        end
    endtask

    // Logica di disponibilità di monete nella macchina
    always @(*) begin
        disponibile = (stock_01 * 10'd1) + (stock_02 * 10'd2) + (stock_05 * 10'd5) + (stock_10 * 10'd10);
    end

// LOGICA SEQUENZIALE
// Logica Sequenziale per registri 
always @(posedge clk or negedge rst) begin
   if (!rst) begin
        state <= IDLE;
        credito <= 6'b0;
        resto <= 6'b0;
        current_price <= 6'b0;
        current_qt <= 6'b0;
        {prodotto1, prodotto2, prodotto3, prodotto4} <= 4'b0000;
        {stock_01, stock_02, stock_05, stock_10} <= 24'b0; // Inizializza lo stock di monete a zero, verrà aggiornato con i valori del setup
        {coin_01, coin_02, coin_05, coin_10} <= 24'b0; // Inizializza le monete da erogare come resto a zero
        errore <= 2'b00; // Nessun errore
   end else if (!setup_done) begin
        stock_01 <= init_stock_01; // Carica lo stock di monete con i valori provenienti dal setup
        stock_02 <= init_stock_02;
        stock_05 <= init_stock_05;
        stock_10 <= init_stock_10;
   end else begin

        case (state)
            IDLE : begin
                {prodotto1, prodotto2, prodotto3, prodotto4} <= 4'b0;
                {coin_01, coin_02, coin_05, coin_10} <= 24'd10;
                errore <= 2'b00;
                resto <= 6'b0;

                if(coin != 3'b000) begin
                    credito <= credito + coin_value(coin);

                    // La macchina incassa la prima moneta
                    if (coin == 3'b100) stock_01 <= stock_01 + 1'b1; // 0.10€
                    else if (coin == 3'b101) stock_02 <= stock_02 + 1'b1; // 0.20€
                    else if (coin == 3'b110) stock_05 <= stock_05 + 1'b1; // 0.50€
                    else if (coin == 3'b111) stock_10 <= stock_10 + 1'b1; // 1.00€

                    state <= ACC_CREDIT;
                end
            end

            ACC_CREDIT : begin
                if (coin != 3'b000) begin
                    credito <= credito + coin_value(coin); // accumulatore

                    // La macchina incassa la seconda moneta
                    if (coin == 3'b100) stock_01 <= stock_01 + 1'b1; // 0.10€
                    else if (coin == 3'b101) stock_02 <= stock_02 + 1'b1; // 0.20€
                    else if (coin == 3'b110) stock_05 <= stock_05 + 1'b1; // 0.50€
                    else if (coin == 3'b111) stock_10 <= stock_10 + 1'b1; // 1.00€
                end else if (annulla) begin
                    state <= DISPENSE;
                end else if (selezione != 3'b000) begin
                    selected_product <= selezione; // Salva la selezione del prodotto
                    case (selezione)
                        3'b100 : begin current_price <= price_p1; current_qt <= qt_p1; end
                        3'b101 : begin current_price <= price_p2; current_qt <= qt_p2; end
                        3'b110 : begin current_price <= price_p3; current_qt <= qt_p3; end
                        3'b111 : begin current_price <= price_p4; current_qt <= qt_p4; end
                        default : begin current_price = 6'd0; current_qt = 6'd0; end
                    endcase
                    state <= SEL_PROD;
                end
            end

            SEL_PROD : begin
                if (annulla) begin
                    state <= DISPENSE;
                end else if (conferma) begin
                    state <= CHECK_AV;
                end else if (selezione != 3'b000) begin
                    selected_product <= selezione; // Salva la selezione del prodotto
                    // MUX per selezionare il prezzo e la quantità del prodotto scelto
                    case (selezione)
                        3'b100 : begin current_price <= price_p1; current_qt <= qt_p1; end
                        3'b101 : begin current_price <= price_p2; current_qt <= qt_p2; end
                        3'b110 : begin current_price <= price_p3; current_qt <= qt_p3; end
                        3'b111 : begin current_price <= price_p4; current_qt <= qt_p4; end
                        default : begin current_price = 6'd0; current_qt = 6'd0; end
                    endcase
                end
            end

            CHECK_AV : begin
                if (credito >= current_price && current_qt > 0) begin
                    state <= DISPENSE;
                end else begin
                // Blocco calcolo errore
                if (credito < current_price && current_qt == 0) errore <= 2'b11; // errore : prezzo non sufficiente e prodotto esaurito
                else if (credito < current_price) errore <= 2'b01; // errore : prezzo non sufficiente
                else if (current_qt == 0) errore <= 2'b10; // errore : prodotto esaurito
                state <= ERROR;
                end
            end

             DISPENSE : begin
                if (annulla) begin
                    resto <= credito;
                    calcolo_greedy(credito); // Calcola il resto in modo greedy
                end else begin
                    resto <= credito - current_price;
                    calcolo_greedy(credito - current_price);              
                    case (selected_product)
                        3'b100: prodotto1 <= 1'b1;
                        3'b101: prodotto2 <= 1'b1;
                        3'b110: prodotto3 <= 1'b1;
                        3'b111: prodotto4 <= 1'b1;
                    endcase
                end

                // Aggiorna lo stock di monete dopo l'erogazione del resto
                stock_10 <= stock_10 - coin_10; 
                stock_05 <= stock_05 - coin_05;
                stock_02 <= stock_02 - coin_02;
                stock_01 <= stock_01 - coin_01;
                credito <= 6'b0; // Reset del credito dopo l'erogazione     

                state <= IDLE; // Torna allo stato iniziale dopo l'erogazione   
            end

            ERROR : begin
                // Dopo la gestione dell'errore, torna allo stato iniziale
                state <= IDLE;
            end
        endcase
   end 
end

endmodule