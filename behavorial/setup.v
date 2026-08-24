module setup (
    input clk,
    input rst,               // reset attivo basso
    input [2:0] coin,
    input [2:0] selezione,
    output reg setup_done,  // Indica se la configurazione è terminata

    // registri per lo storage (output verso il circuito per l'utilizzo)
    output reg [5:0] qt_p1, qt_p2, qt_p3, qt_p4,
    output reg [5:0] price_p1, price_p2, price_p3, price_p4,
    output reg [5:0] stock_01, stock_02, stock_05, stock_10
);

    // Stato del setup (4 bit per rappresentare fino a 12 cicli)
    reg [3:0] counter;
    wire [5:0] data_in = {coin, selezione}; // Combina coin e selezione in un unico bus dati

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            counter <= 4'd0;
            setup_done <= 1'b0;

            // impostare tutti i registri a zero all'inizio del reset
            {qt_p1, qt_p2, qt_p3, qt_p4}             <= 24'd0;   // 6 bit per ogni registro 6*4 = 24
            {price_p1, price_p2, price_p3, price_p4} <= 24'd0;
            {stock_01, stock_02, stock_05, stock_10} <= 24'd0;   
              
        end else if (counter < 4'd12) begin
            case (counter)
                // inizio prodotti
                4'd0: qt_p1 <= data_in;     // Ciclo 0  : carica qt_p1
                4'd1: price_p1 <= data_in;  // Ciclo 1  : carica price_p1
                4'd2: qt_p2 <= data_in;     // Ciclo 2  : carica qt_p2
                4'd3: price_p2 <= data_in;  // Ciclo 3  : carica price_p2

                4'd4: qt_p3 <= data_in;     // Ciclo 4  : carica qt_p3
                4'd5: price_p3 <= data_in;  // Ciclo 5  : carica price_p3
                4'd6: qt_p4 <= data_in;     // Ciclo 6  : carica qt_p4
                4'd7: price_p4 <= data_in;  // Ciclo 7  : carica price_p4
                // fine prodotti

                // inizio monete
                4'd8: stock_01 <= data_in;  // Ciclo 8  : carica stock_01
                4'd9: stock_02 <= data_in;  // Ciclo 9  : carica stock_02
                4'd10: stock_05 <= data_in; // Ciclo 10 : carica stock_05
                4'd11: stock_10 <= data_in; // Ciclo 11 : carica stock_10

                default : ; // Non fare nulla per i cicli oltre il 11
            endcase

            // Incrementa il contatore ad ogni ciclo di clock
            counter <= counter + 1'b1; // Incrementa il contatore ad ogni ciclo

        end else begin
                setup_done <= 1'b1; // Indica che la configurazione è terminata dopo il ciclo 11
        end
    end

endmodule