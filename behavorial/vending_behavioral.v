module vending_behavioral (
    input clk,
    input rst,
    input [2:0] coin,
    input [2:0] selezione,
    input conferma,
    input annulla,

    // Segnali di uscita
    output prodotto1, prodotto2, prodotto3, prodotto4,
    output [5:0] credito,
    output [1:0] errore,
    output [5:0] resto,
    output [9:0] disponibile,
    output [5:0] coin_01, coin_02, coin_05, coin_10
);

// WIRE
// Fili che trasportao i datai dal setup allo user
wire w_setup_done;
wire [5:0] w_qt_p1, w_qt_p2, w_qt_p3, w_qt_p4;
wire [5:0] w_price_p1, w_price_p2, w_price_p3, w_price_p4;
wire [5:0] w_coin_01, w_coin_02, w_coin_05, w_coin_10;

// Istanza del modulo di setup
setup setup_inst (
    .clk(clk),
    .rst(rst),
    .coin(coin),
    .selezione(selezione),
    .setup_done(w_setup_done),
    .qt_p1(w_qt_p1), .qt_p2(w_qt_p2), .qt_p3(w_qt_p3), .qt_p4(w_qt_p4),
    .price_p1(w_price_p1), .price_p2(w_price_p2), .price_p3(w_price_p3), .price_p4(w_price_p4),
    .stock_01(w_coin_01), .stock_02(w_coin_02), .stock_05(w_coin_05), .stock_10(w_coin_10)
);

// Istanza del mdodulo utente
user_behavioral logic_unit (
    .clk(clk),
    .rst(rst),
    .setup_done(w_setup_done),
    .coin(coin),
    .selezione(selezione),
    .conferma(conferma),
    .annulla(annulla),
    
    // Dati provenienti dal setup
    .qt_p1(w_qt_p1), .qt_p2(w_qt_p2), .qt_p3(w_qt_p3), .qt_p4(w_qt_p4),
    .price_p1(w_price_p1), .price_p2(w_price_p2), .price_p3(w_price_p3), .price_p4(w_price_p4),
    .init_stock_01(w_coin_01), .init_stock_02(w_coin_02), .init_stock_05(w_coin_05), .init_stock_10(w_coin_10),

    // Uscite del sistema
    .prodotto1(prodotto1), .prodotto2(prodotto2), .prodotto3(prodotto3), .prodotto4(prodotto4),
    .credito(credito),
    .errore(errore),
    .resto(resto),
    .disponibile(disponibile),
    .coin_01(coin_01), .coin_02(coin_02), .coin_05(coin_05), .coin_10(coin_10)
);

endmodule