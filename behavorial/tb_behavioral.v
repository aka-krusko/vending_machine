`timescale 1ns / 1ps

module tb_behavioral();

    // Segnali di ingresso
    reg clk;
    reg rst;
    reg setup_done;
    reg [2:0] coin;
    reg [2:0] selezione;
    reg conferma;
    reg annulla;

    // Segnali di uscita
    wire prodotto1, prodotto2, prodotto3, prodotto4;
    wire [5:0] credito;
    wire [1:0] errore;
    wire [5:0] resto;
    wire [9:0] disponibile;
    wire [5:0] coin_01, coin_02, coin_05, coin_10; // Conteggi monete per il calcolo greedy

    vending_behavioral uut (
        .clk(clk),
        .rst(rst),
        .coin(coin),
        .selezione(selezione),
        .conferma(conferma),
        .annulla(annulla),

        .prodotto1(prodotto1), .prodotto2(prodotto2), .prodotto3(prodotto3), .prodotto4(prodotto4),
        .credito(credito),
        .errore(errore),
        .resto(resto),
        .disponibile(disponibile),

        .coin_01(coin_01), .coin_02(coin_02), .coin_05(coin_05), .coin_10(coin_10)
    );

    always #5 clk = ~clk; 
    
    // Inserimento dati di setup
    task setup_data (input [5:0] data_in);
        begin
            @(negedge clk);
            coin = data_in[5:3]; // Estrae i bit di coin
            selezione = data_in[2:0]; // Estrae i bit di selezione
        end
    endtask

    // Inserimento moneta da parte dell'utente
    task insert_coin (input [2:0] coin_in);
        begin
            @(negedge clk)
            coin = coin_in;
            #10; // Attende un ciclo di clock
            coin = 3'b000; // Resetta il segnale di coin
        end
    endtask


    initial begin
        // Inizializzazione dei segnali
        clk = 0;
        rst = 0;
        setup_done = 0;
        coin = 3'b000;
        selezione = 3'b000;
        conferma = 0;
        annulla = 0;

        #7 rst = 1;

        // FASE DI SETUP (12 cicli di clock)
        // Config. Prodotto 1 : 10 unità a 15 (1.50€)
        setup_data(6'd10); // Ciclo 1: Qt Prodotto 1 = 10
        setup_data(6'd15); // Ciclo 2: Pr Prodotto 1 = 15 decimi (1.50€)
        
        setup_data(6'd5);  // Ciclo 3: Qt Prodotto 2 = 5
        setup_data(6'd20); // Ciclo 4: Pr Prodotto 2 = 20 decimi (2.00€)
        
        setup_data(6'd5);  // Ciclo 5: Qt Prodotto 3 = 5
        setup_data(6'd30); // Ciclo 6: Pr Prodotto 3 = 30 decimi (3.00€)
        
        setup_data(6'd5);  // Ciclo 7: Qt Prodotto 4 = 5
        setup_data(6'd40); // Ciclo 8: Pr Prodotto 4 = 40 decimi (4.00€)
        
        // Setup Scorte Monete Iniziali
        setup_data(6'd10); // Ciclo 9:  10 monete da 0.10€
        setup_data(6'd10); // Ciclo 10: 10 monete da 0.20€
        setup_data(6'd10); // Ciclo 11: 10 monete da 0.50€
        setup_data(6'd10); // Ciclo 12: 10 monete da 1.00€

        // Fine del setup. Reset ingressi
        @(negedge clk);
        coin = 3'b000; selezione = 3'b000;
        #40; // Attende un ciclo di clock per assicurarsi che il setup sia completato
        $display("SETUP COMPLETATO. Disponibile iniziale : %d", disponibile);

        // FASE DI ACQUISTO
        // Test 1: Acquisto prodotto 1 con monete da 1.
        $display("\nTEST 1: Acquisto prodotto 1 con monete da 1.");
        insert_coin(3'b111); // Inserisce 1
        insert_coin(3'b111); // Inserisce 1
        #20; // Attende un ciclo di clock per aggiornare il credito

        @(negedge clk);
        selezione = 3'b100; // Seleziona prodotto 1
        conferma = 1; // Conferma la selezione

        repeat(4) @(negedge clk);

        if (prodotto1 == 1'b1) begin
            $display("Acquisto prodotto 1 riuscito. Resto da erogare: %d", resto);
            $display("Calcolo greedy per il resto: %d monete da 1.00€, %d monete da 0.50€, %d monete da 0.20€, %d monete da 0.10€", coin_10, coin_05, coin_02, coin_01);
            $display("Disponibile dopo l'acquisto: %d", disponibile);
        end else begin
            $display("Acquisto prodotto 1 fallito. Errore: %b", errore);
        end
        
        @(negedge clk);
        conferma = 0; 
        selezione = 3'b000; // Resetta selezione e conferma

        // Test 2: Annullamento Transazione dopo inserimento moneta
        #20;
        $display("\nTEST 2: Annullamento transazione dopo inserimento moneta.");
        insert_coin(3'b100); // Inserisce 0.10€
        #20;
        annulla = 1; // Annulla la transazione
        #20 annulla = 0; // Resetta il segnale di annullamento

        if (resto != 6'b000000) // Verifica che il resto sia correttamente erogato
            $display("Transazione annullata correttamente. Resto erogato: %d", resto);
        else
            $display("Errore nell'annullamento. Resto erogato: %d", resto); 
    #40;
    $finish;
    end

    initial begin
        $monitor("Tempo : %0t | Stato FSM : %b | Credito : %d | Errore : %b | Resto : %d | Disponibile : %d", $time, uut.logic_unit.state, credito, errore, resto, disponibile);
    end
endmodule
        