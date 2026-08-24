module datapath (
    input clk,
    input rst,

    // Ingressi utente
    input [2:0] coin, selezione,
    input conferma, annulla,

    // Storage dal setup
    input [5:0] qt1, qt2, qt3, qt4,
    input [5:0] price1, price2, price3, price4,
    input [5:0] coin01, coin02, coin05, coin10,

    // Comandi dalla FSM
    input load, eroga, azzera_credito,

    // Flag per la FSM
    output ok_prezzo, prod_disponibile,

    // Uscite globali
    output [5:0] credito, resto,
    output [9:0] disponibile,
    output [1:0] errore,
    output prodotto1, prodotto2, prodotto3, prodotto4
);

    // 1. Cavi di stato interni (uscite dei registri)
    wire [5:0] run_qt1, run_qt2, run_qt3, run_qt4;

    //2. MUX per decodifica ingressi (monete e selezioni)
    wire [5:0] valore_moneta, moneta_valida;
    wire [5:0] p_scelto, p_selezionato;
    wire [5:0] q_scelta, q_selezionata;

    // Selettore moneta
    mux4 #(.WIDTH(6)) mux_moneta_L1 (
        .d0(6'd1), .d1(6'd2), .d2(6'd5), .d3(6'd10),
        .sel(coin[1:0]), .y(moneta_valida)
    );
    mux2 #(.WIDTH(6)) mux_moneta_L2 (
        .d0(6'd0), .d1(moneta_valida),
        .sel(coin[2]), .y(valore_moneta)
    );

    // Selettore prezzo
    mux4 #(.WIDTH(6)) mux_prezzi_L1 (
        .d0(price1), .d1(price2), .d2(price3), .d3(price4),
        .sel(selezione[1:0]), .y(p_selezionato)
    );
    mux2 #(.WIDTH(6)) mux_prezzi_L2 (
        .d0(6'd0), .d1(p_selezionato),
        .sel(selezione[2]), .y(p_scelto)
    );

    // Selettore quantità
    mux4 #(.WIDTH(6)) mux_qt_L1 (
        .d0(run_qt1), .d1(run_qt2), .d2(run_qt3), .d3(run_qt4),
        .sel(selezione[1:0]), .y(q_selezionata)
    );
    mux2 #(.WIDTH(6)) mux_qt_L2 (
        .d0(6'd0), .d1(q_selezionata),
        .sel(selezione[2]), .y(q_scelta)
    );

    // 3. Comparatori
    wire int_ok_prezzo;
    wire int_prod_disponibile;

    assign ok_prezzo = int_ok_prezzo;
    assign prod_disponibile = int_prod_disponibile;

    greater_equal cmp_prezzo (
        .a(credito),
        .b(p_scelto),
        .ge(int_ok_prezzo)
    );

    greater_than_zero cmp_prod (
        .a(q_scelta),
        .greater(int_prod_disponibile)
    );

    // 4. Rete aritmetica (calcolo credito e resto)
    wire [5:0] sum_credito, calcolo_credito;
    wire [5:0] diff_resto, resto_raw, calcolo_resto;
    wire [5:0] not_p_scelto;

    // Addizione : credito + valore_moneta
    adder_6bit add_credito (
        .a(credito),
        .b(valore_moneta),
        .cin(1'b0),
        .sum(sum_credito),
        .cout()
    );
    mux2 #(.WIDTH(6)) mux_cred_azzerato (
        .d0(sum_credito), 
        .d1(6'd0),
        .sel(azzera_credito), 
        .y(calcolo_credito)
    );

    // Sottrazione in complemento a due : credito - p_scelto
    assign not_p_scelto = ~p_scelto;

    adder_6bit sub_resto (
        .a(credito),
        .b(not_p_scelto),
        .cin(1'b1),
        .sum(diff_resto),
        .cout()
    );

    mux2 #(.WIDTH(6)) mux_resto_annulla (
        .d0(diff_resto), 
        .d1(credito),
        .sel(annulla), 
        .y(resto_raw)
    );
    mux2 #(.WIDTH(6)) mux_resto_eroga (
        .d0(6'd0), 
        .d1(resto_raw),
        .sel(eroga), 
        .y(calcolo_resto)
    );

    // 5. Aggiornamento quantità in magazzino
    wire dispense = eroga & ~annulla & conferma;

    wire erogap1 = dispense & (selezione == 3'b100);
    wire erogap2 = dispense & (selezione == 3'b101);
    wire erogap3 = dispense & (selezione == 3'b110);
    wire erogap4 = dispense & (selezione == 3'b111);

    // Nodi della pipeline di elaborazione
    wire [5:0] qt1_dec, qt2_dec, qt3_dec, qt4_dec;
    wire [5:0] qt1_upd, qt2_upd, qt3_upd, qt4_upd;
    wire [5:0] qt1_load, qt2_load, qt3_load, qt4_load;

    // decremento logico (somma con -1)
    adder_6bit dec_qt1 (.a(run_qt1), .b(6'b111111), .cin(1'b0), .sum(qt1_dec), .cout());
    adder_6bit dec_qt2 (.a(run_qt2), .b(6'b111111), .cin(1'b0), .sum(qt2_dec), .cout());
    adder_6bit dec_qt3 (.a(run_qt3), .b(6'b111111), .cin(1'b0), .sum(qt3_dec), .cout());
    adder_6bit dec_qt4 (.a(run_qt4), .b(6'b111111), .cin(1'b0), .sum(qt4_dec), .cout());

    // MUX Erogazione o Mantenimento
    mux2 #(.WIDTH(6)) mux_upd1 (.d0(run_qt1), .d1(qt1_dec), .sel(erogap1), .y(qt1_upd));
    mux2 #(.WIDTH(6)) mux_upd2 (.d0(run_qt2), .d1(qt2_dec), .sel(erogap2), .y(qt2_upd));
    mux2 #(.WIDTH(6)) mux_upd3 (.d0(run_qt3), .d1(qt3_dec), .sel(erogap3), .y(qt3_upd));
    mux2 #(.WIDTH(6)) mux_upd4 (.d0(run_qt4), .d1(qt4_dec), .sel(erogap4), .y(qt4_upd));

    // MUX Override forzato durante il Setup (Load)
    mux2 #(.WIDTH(6)) mux_load1 (.d0(qt1_upd), .d1(qt1), .sel(load), .y(qt1_load));
    mux2 #(.WIDTH(6)) mux_load2 (.d0(qt2_upd), .d1(qt2), .sel(load), .y(qt2_load));
    mux2 #(.WIDTH(6)) mux_load3 (.d0(qt3_upd), .d1(qt3), .sel(load), .y(qt3_load));
    mux2 #(.WIDTH(6)) mux_load4 (.d0(qt4_upd), .d1(qt4), .sel(load), .y(qt4_load));

    // 6. Gestione errore
    wire [1:0] calcolo_errore;
    wire [1:0] bridge_errore;
    wire load_errore;
    wire not_ok, not_disp, err_combinato;
    wire [1:0] codice_errore;

    not (not_ok, int_ok_prezzo);
    not (not_disp, int_prod_disponibile);
    or  (err_combinato, not_ok, not_disp);
    and (load_errore, conferma, err_combinato);

    // Premuto conferma e manca almeno qualcosa
    assign codice_errore = {not_disp, not_ok};

    // selezione tra errore attuale e nuovo codice di errore
    mux2 #(.WIDTH(2)) mux_err_L1 (
        .d0(errore),
        .d1(codice_errore),
        .sel(load_errore),
        .y(bridge_errore)
    );

    // azzeramento
    mux2 #(.WIDTH(2)) mux_err_L2 (
        .d0(bridge_errore),
        .d1(2'b00),
        .sel(azzera_credito),
        .y(calcolo_errore)
    );

    // 7. Memorie fisiche e registri
    // Registri delle quantità
    registro reg_qt1 (.clk(clk), .rst(rst), .enable(1'b1), .d(qt1_load), .q(run_qt1));
    registro reg_qt2 (.clk(clk), .rst(rst), .enable(1'b1), .d(qt2_load), .q(run_qt2));
    registro reg_qt3 (.clk(clk), .rst(rst), .enable(1'b1), .d(qt3_load), .q(run_qt3));
    registro reg_qt4 (.clk(clk), .rst(rst), .enable(1'b1), .d(qt4_load), .q(run_qt4));

    // Registri di credito e resto
    registro reg_credito (.clk(clk), .rst(rst), .enable(1'b1), .d(calcolo_credito), .q(credito));
    registro reg_resto   (.clk(clk), .rst(rst), .enable(1'b1), .d(calcolo_resto),   .q(resto));

    // Registri di errore (Flip-Flop a 1 bit)
    ff ff_err0 (.clk(clk), .rst(rst), .d(calcolo_errore[0]), .q(errore[0]));
    ff ff_err1 (.clk(clk), .rst(rst), .d(calcolo_errore[1]), .q(errore[1]));

    // Registri di erogazione prodotti (Flip-Flop a 1 bit)
    ff ff_prod1 (.clk(clk), .rst(rst), .d(erogap1), .q(prodotto1));
    ff ff_prod2 (.clk(clk), .rst(rst), .d(erogap2), .q(prodotto2));
    ff ff_prod3 (.clk(clk), .rst(rst), .d(erogap3), .q(prodotto3));
    ff ff_prod4 (.clk(clk), .rst(rst), .d(erogap4), .q(prodotto4));

    // 8. disponibilità di cassa
    assign disponibile = {4'b0, coin01} 
                       + ({4'b0, coin02} << 1) 
                       + (({4'b0, coin05} << 2) + {4'b0, coin05}) 
                       + (({4'b0, coin10} << 3) + ({4'b0, coin10} << 1)) 
                       + {4'b0, credito};

    endmodule