`timescale 1ns/1ps

module tb_structural;
    // Ingressi (Stimoli)
    reg clk;
    reg rst;
    reg [2:0] coin, selezione;
    reg conferma, annulla;

    // Uscite (Sonde)
    wire setup_done; // <-- Aggiunto per monitorare la fine dell'inizializzazione
    wire prodotto1, prodotto2, prodotto3, prodotto4;
    wire [5:0] credito;
    wire [1:0] errore;
    wire [5:0] resto;
    wire [9:0] disponibile;

    // Istanziazione del modulo strutturale puro (Device Under Test)
    vending_machine DUT (
        .clk(clk), 
        .rst(rst),
        .coin(coin), 
        .selezione(selezione), 
        .conferma(conferma), 
        .annulla(annulla),
        
        .setup_done(setup_done), // <-- Collegato
        
        .prodotto1(prodotto1), 
        .prodotto2(prodotto2), 
        .prodotto3(prodotto3), 
        .prodotto4(prodotto4),
        
        .credito(credito), 
        .errore(errore), 
        .resto(resto), 
        .disponibile(disponibile)
    );

    // Generatore di Clock (Periodo 10ns)
    always #5 clk = ~clk;

    // Timeout di sicurezza
    initial begin
        #5000;
        $display("Timeout raggiunto");
        $finish;
    end

    // Monitoraggio a terminale
    initial begin
        $monitor("Tempo :%0t | SDone: %b | Credito : %d | Sel : %b | Conf : %b | Ann : %b || Erogato : P1=%b P2=%b P3=%b P4=%b | Resto : %d | Err : %b | Disponibile : %d ",
                $time, setup_done, credito, selezione, conferma, annulla, prodotto1, prodotto2, prodotto3, prodotto4, resto, errore, disponibile);
    end

    // Sequenza di Test
    initial begin
        $dumpfile("simulazione_structural.vcd");
        $dumpvars(0, tb_structural);

        // INIZIALIZZAZIONE
        clk = 0;
        rst = 1;
        coin = 3'b000; selezione = 3'b000;
        conferma = 0; annulla = 0;

        // Reset asincrono (attivo basso)
        #2 rst = 0;
        #10 rst = 1;

        $display("INIZIO FASE DI SETUP");

        // Ciclo 0-1: Prodotto 1 (Qt=5, Prezzo=10 decimi -> 1.00€)
        {coin, selezione} = 6'd5;  
        @(negedge clk); {coin, selezione} = 6'd10; 
        
        // Ciclo 2-3: Prodotto 2 (Qt=2, Prezzo=15 decimi -> 1.50€)
        @(negedge clk); {coin, selezione} = 6'd2;  
        @(negedge clk); {coin, selezione} = 6'd15; 
        
        // Ciclo 4-5: Prodotto 3 (Qt=0 [ESAURITO], Prezzo=5 decimi -> 0.50€)
        @(negedge clk); {coin, selezione} = 6'd0;  
        @(negedge clk); {coin, selezione} = 6'd5;  
        
        // Ciclo 6-7: Prodotto 4 (Qt=10, Prezzo=20 decimi -> 2.00€)
        @(negedge clk); {coin, selezione} = 6'd10; 
        @(negedge clk); {coin, selezione} = 6'd20; 
        
        // Cicli 8-11: Stock Iniziale Monete (10 monete per ogni taglio)
        @(negedge clk); {coin, selezione} = 6'd1;  // 0.10
        @(negedge clk); {coin, selezione} = 6'd2;  // 0.20
        @(negedge clk); {coin, selezione} = 6'd5;  // 0.50
        @(negedge clk); {coin, selezione} = 6'd10; // 1.00

        // Attesa fine setup
        @(negedge clk); {coin, selezione} = 6'd0;
        
        // Aspettiamo finché il segnale setup_done non va a 1
        wait(setup_done == 1'b1);
        #10;
        $display("SETUP COMPLETATO --- Disponibile in cassa : %d decimi", disponibile);

        // TEST 1
        $display("\n--- TEST 1: Acquisto P1 (10 decimi) con 15 decimi ---");
        @(negedge clk); coin = 3'b111; // Inserisce 1.00€ (Credito = 10)
        @(negedge clk); coin = 3'b110; // Inserisce 0.50€ (Credito = 15)
        @(negedge clk); coin = 3'b000;
        
        @(negedge clk); selezione = 3'b100; // Seleziona P1
        @(negedge clk); conferma = 1;       // Conferma acquisto
        
        // Aspettiamo che la FSM faccia le sue transizioni
        #40; 

        @(negedge clk); conferma = 0;
        @(negedge clk); selezione = 3'b000;
        #20;
    
        // TEST 2
        $display("\n--- TEST 2: Inserimento soldi e Annullamento ---");
        @(negedge clk); coin = 3'b111; // Inserisce 1.00€
        @(negedge clk); coin = 3'b000;
        #10;
        @(negedge clk); annulla = 1;   // Preme Annulla
        
        #40;
        @(negedge clk); annulla = 0;
        #20;

        // TEST 3
        $display("\n--- TEST 3: Generazione Errore 11 ---");
        @(negedge clk); coin = 3'b100; // Inserisce 0.10€ (Il prezzo di P3 è 0.50€)
        @(negedge clk); coin = 3'b000;
        
        @(negedge clk); selezione = 3'b110; // Seleziona P3 (Impostato a 0 nel setup)
        @(negedge clk); conferma = 1;       // Conferma
        #40;
        @(negedge clk); conferma = 0; 
        @(negedge clk); selezione = 3'b000;
        @(negedge clk); annulla = 1;
        #40;
        @(negedge clk); annulla = 0;
        #20;

        $display("\n--- SIMULAZIONE COMPLETATA CON SUCCESSO ---");
        $finish;
    end

endmodule