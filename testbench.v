`timescale 1ns/1ps

module testbench;
    // 1. Ingressi Comuni (Stimoli)
    reg clk, rst;
    reg [2:0] coin, selezione;
    reg conferma, annulla;

    // 2. Uscite Modello Strutturale
    wire s_setup_done;
    wire s_p1, s_p2, s_p3, s_p4;
    wire [5:0] s_credito, s_resto;
    wire [1:0] s_errore;
    wire [9:0] s_disponibile;

    // 3. Uscite Modello Comportamentale
    wire b_setup_done;
    wire b_p1, b_p2, b_p3, b_p4;
    wire [5:0] b_credito, b_resto;
    wire [1:0] b_errore;
    wire [9:0] b_disponibile;

    // 4. Istanziazione dei due moduli
    vending_machine DUT_STRUCT (
        .clk(clk), 
        .rst(rst), 
        .coin(coin), 
        .selezione(selezione), 
        .conferma(conferma), 
        .annulla(annulla),
        .setup_done(s_setup_done), 
        .prodotto1(s_p1), .prodotto2(s_p2), .prodotto3(s_p3), .prodotto4(s_p4),
        .credito(s_credito), 
        .errore(s_errore), 
        .resto(s_resto), 
        .disponibile(s_disponibile)
    );

    vending_behavioral DUT_BEHAV (
        .clk(clk), 
        .rst(rst), 
        .coin(coin), 
        .selezione(selezione), 
        .conferma(conferma), 
        .annulla(annulla),
        .setup_done(b_setup_done), 
        .prodotto1(b_p1), .prodotto2(b_p2), .prodotto3(b_p3), .prodotto4(b_p4),
        .credito(b_credito), 
        .errore(b_errore), 
        .resto(b_resto), 
        .disponibile(b_disponibile)
    );

    // 5. Generatore di Clock
    always #5 clk = ~clk;

    // 6. Rilevatore automatico di disallineamento (Equivalence Checker)
    wire mismatch = (s_setup_done != b_setup_done) ||
                    (s_p1 != b_p1) || (s_p2 != b_p2) || (s_p3 != b_p3) || (s_p4 != b_p4) ||
                    (s_credito != b_credito) || 
                    (s_resto != b_resto) || 
                    (s_errore != b_errore) || 
                    (s_disponibile != b_disponibile);

    always @(negedge clk) begin
        if (mismatch && rst) begin
            $display("\n[!] ALLARME DISALLINEAMENTO AL TEMPO %0t [!]", $time);
            $display("STRUCTURAL: P1=%b Credito=%d Resto=%d Err=%b", s_p1, s_credito, s_resto, s_errore);
            $display("BEHAVIORAL: P1=%b Credito=%d Resto=%d Err=%b", b_p1, b_credito, b_resto, b_errore);
            $finish; // Ferma subito la simulazione se c'è un errore
        end
    end

    // 7. Sequenza di Test
    initial begin
        $dumpfile("simulazione_compare.vcd");
        $dumpvars(0, testbench);

        // INIZIALIZZAZIONE
        clk = 0; 
        rst = 1; 
        coin = 0; 
        selezione = 0; 
        conferma = 0; 
        annulla = 0;
        
        #2 rst = 0; 
        #10 rst = 1;

        $display("INIZIO SETUP...");
        {coin, selezione} = 6'd5;  
        @(negedge clk); {coin, selezione} = 6'd10; // P1 (5, 10 decimi)
        @(negedge clk); {coin, selezione} = 6'd2;  
        @(negedge clk); {coin, selezione} = 6'd15; // P2 (2, 15 decimi)
        @(negedge clk); {coin, selezione} = 6'd0;  
        @(negedge clk); {coin, selezione} = 6'd5;  // P3 (0, 5 decimi) - ESAURITO
        @(negedge clk); {coin, selezione} = 6'd10; 
        @(negedge clk); {coin, selezione} = 6'd20; // P4 (10, 20 decimi)
        
        // Monete: 10 per tipo
        @(negedge clk); {coin, selezione} = 6'd1;  
        @(negedge clk); {coin, selezione} = 6'd2;  
        @(negedge clk); {coin, selezione} = 6'd5;  
        @(negedge clk); {coin, selezione} = 6'd10; 

        @(negedge clk); {coin, selezione} = 6'd0;
        wait(s_setup_done == 1'b1);
        #10; $display("SETUP COMPLETATO.");

        // --- TEST 1: Acquisto P1 con Resto (1.50 inseriti, prezzo 1.00) ---
        $display("TEST 1: P1 con resto");
        @(negedge clk); coin = 3'b111; 
        @(negedge clk); coin = 3'b110; 
        @(negedge clk); coin = 3'b000; selezione = 3'b100; conferma = 1;
        #40; @(negedge clk); conferma = 0; selezione = 0; #20;

        // --- TEST 2: Annullamento ---
        $display("TEST 2: Inserimento e Annulla");
        @(negedge clk); coin = 3'b111; 
        @(negedge clk); coin = 3'b000; annulla = 1;
        #40; @(negedge clk); annulla = 0; #20;

        // --- TEST 3: Errore Doppio (Senza soldi su prodotto esaurito) ---
        $display("TEST 3: Errore 11 su P3");
        @(negedge clk); coin = 3'b100; 
        @(negedge clk); coin = 3'b000; selezione = 3'b110; conferma = 1;
        #40; @(negedge clk); conferma = 0; selezione = 0; annulla = 1;
        #40; @(negedge clk); annulla = 0; #20;

        // --- TEST 4: Acquisto P2 cifra esatta (Nessun resto) ---
        $display("TEST 4: P2 con cifra esatta (1.50)");
        @(negedge clk); coin = 3'b111; // + 1.00
        @(negedge clk); coin = 3'b110; // + 0.50 = 1.50
        @(negedge clk); coin = 3'b000; selezione = 3'b101; conferma = 1;
        #40; @(negedge clk); conferma = 0; selezione = 0; #20;

        // --- TEST 5: Due acquisti P1 consecutivi veloci ---
        $display("TEST 5: Acquisti multipli P1");
        // Acquisto 1
        @(negedge clk); coin = 3'b111; 
        @(negedge clk); coin = 3'b000; selezione = 3'b100; conferma = 1;
        #40; @(negedge clk); conferma = 0;
        // Acquisto 2 subito dopo
        @(negedge clk); coin = 3'b111; 
        @(negedge clk); coin = 3'b000; selezione = 3'b100; conferma = 1;
        #40; @(negedge clk); conferma = 0; selezione = 0; #20;

        // --- TEST 6: Reset improvviso durante l'inserimento monete ---
        $display("TEST 6: Reset Hardware a metà transazione");
        @(negedge clk); coin = 3'b111; 
        @(negedge clk); rst = 0; // BAM! Salta la corrente
        #15; rst = 1; coin = 0;
        #20;

        $display("\n--- SUCCESSO: Entrambi i moduli si sono comportati in modo identico al 100%%! ---");
        $finish;
    end
endmodule