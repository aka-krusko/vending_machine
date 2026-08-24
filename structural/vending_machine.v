module vending_machine (
    input clk,
    input rst,
    
    // Ingressi Utente
    input [2:0] coin,
    input [2:0] selezione,
    input conferma,
    input annulla,

    // Uscite Globali
    output setup_done,         
    output [5:0] credito,
    output [5:0] resto,
    output [9:0] disponibile,
    output [1:0] errore,
    output prodotto1,
    output prodotto2,
    output prodotto3,
    output prodotto4
);
    
    // Bus dati dal Setup al Datapath (Valori iniziali)
    wire [5:0] init_qt1, init_qt2, init_qt3, init_qt4;
    wire [5:0] init_price1, init_price2, init_price3, init_price4;
    wire [5:0] init_coin01, init_coin02, init_coin05, init_coin10;

    // Segnali di controllo dalla FSM al Datapath
    wire ctrl_load;
    wire ctrl_eroga;
    wire ctrl_azzera_credito;

    // Flag di stato dal Datapath alla FSM
    wire flag_ok_prezzo;
    wire flag_prod_disponibile;

    // 1. Modulo di setup
    setup inst_setup (
        .clk(clk),
        .rst(rst),
        .coin(coin),
        .selezione(selezione),
        .setup_done(setup_done), 
        
        .qt1(init_qt1),         .price1(init_price1),
        .qt2(init_qt2),         .price2(init_price2),
        .qt3(init_qt3),         .price3(init_price3),
        .qt4(init_qt4),         .price4(init_price4),
        
        .coin01(init_coin01),   .coin02(init_coin02), 
        .coin05(init_coin05),   .coin10(init_coin10)
    );

    // 2. FSM
    fsm inst_controller (
        .clk(clk),
        .rst(rst),
        
        .setup_done(setup_done),
        .coin(coin),
        .selezione(selezione),
        .conferma(conferma),
        .annulla(annulla),
        
        .ok_prezzo(flag_ok_prezzo),
        .prod_disponibile(flag_prod_disponibile),
        
        .load(ctrl_load),
        .eroga(ctrl_eroga),
        .azzera_credito(ctrl_azzera_credito)
    );

    // 3. DATAPATH
    datapath inst_datapath (
        .clk(clk),
        .rst(rst),
        
        .coin(coin),
        .selezione(selezione),
        .conferma(conferma),
        .annulla(annulla),

        .qt1(init_qt1),         .qt2(init_qt2), 
        .qt3(init_qt3),         .qt4(init_qt4),
        .price1(init_price1),   .price2(init_price2), 
        .price3(init_price3),   .price4(init_price4),
        .coin01(init_coin01),   .coin02(init_coin02), 
        .coin05(init_coin05),   .coin10(init_coin10),

        .load(ctrl_load),
        .eroga(ctrl_eroga),
        .azzera_credito(ctrl_azzera_credito),

        .ok_prezzo(flag_ok_prezzo),
        .prod_disponibile(flag_prod_disponibile),
        
        .credito(credito),
        .resto(resto),
        .disponibile(disponibile),
        .errore(errore),
        .prodotto1(prodotto1),
        .prodotto2(prodotto2),
        .prodotto3(prodotto3),
        .prodotto4(prodotto4)
    );

endmodule