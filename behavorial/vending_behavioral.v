module vending_behavioral (
    input clk,
    input rst,

    // Ingressi fisici dell'utente
    input [2:0] coin,
    input [2:0] selezione,
    input conferma,
    input annulla,

    // Segnali in uscita verso l'esterno
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

    // 1. MACCHINA A STATI (FSM)
    // Assegniamo un nome a ogni stato per non impazzire con i numeri binari
    localparam SETUP      = 3'b000;
    localparam IDLE       = 3'b001;
    localparam ACC_CREDIT = 3'b010;
    localparam SEL_PROD   = 3'b011;
    localparam CHECK_AV   = 3'b100;
    localparam DISPENSE   = 3'b101;
    localparam ERROR      = 3'b110;

    reg [2:0] state, next_state; // Registri per memorizzare lo stato attuale e il prossimo

    // 2. MEMORIE INTERNE (Registri del Datapath)
    // Qui salviamo i dati di configurazione e quelli che cambiano durante l'uso
    reg [3:0] setup_count; // Conta fino a 12 durante la fase iniziale

    // Variabili fisse caricate all'avvio (Prezzi, Quantità iniziali e Monete in cassa)
    reg [5:0] setup_qt1, setup_qt2, setup_qt3, setup_qt4;
    reg [5:0] setup_price1, setup_price2, setup_price3, setup_price4;
    reg [5:0] setup_c01, setup_c02, setup_c05, setup_c10;

    // Variabili "vive" (le quantità che scendono, i soldi inseriti, ecc.)
    reg [5:0] run_qt1, run_qt2, run_qt3, run_qt4; // Magazzino attuale
    reg [5:0] credito_reg;
    reg [5:0] resto_reg;
    reg [1:0] errore_reg;

    // Segnali per comandare le operazioni
    reg load_reg;           // Segnale per caricare i dati dal setup al magazzino
    reg eroga_reg;          // Segnale che fa scattare l'erogazione
    reg azzera_credito_reg; // Segnale per svuotare il credito a fine acquisto

    // 3. LETTURA INGRESSI (Traduzione da codici a numeri reali)
    reg [5:0] valore_moneta;
    
    // Traduciamo i 3 bit della moneta in decimi di euro per fare i calcoli
    always @(*) begin
        // Il bit [2] a '1' significa che è stata inserita una moneta valida
        if (coin[2]) begin
            case (coin[1:0])
                2'b00:   valore_moneta = 6'd1;   // 0.10 € (1 decimo)
                2'b01:   valore_moneta = 6'd2;   // 0.20 € (2 decimi)
                2'b10:   valore_moneta = 6'd5;   // 0.50 € (5 decimi)
                2'b11:   valore_moneta = 6'd10;  // 1.00 € (10 decimi)
                default: valore_moneta = 6'd0;
            endcase
        end else begin
            valore_moneta = 6'd0; // Nessuna moneta inserita
        end
    end

    // Capiamo quale prodotto ha scelto l'utente e peschiamo il suo prezzo e la sua quantità
    reg [5:0] p_scelto;
    reg [5:0] q_scelta;
    
    always @(*) begin
        // Il bit [2] a '1' significa che la selezione è valida (da P1 a P4)
        if (selezione[2]) begin
            case (selezione[1:0])
                2'b00:   begin p_scelto = setup_price1; q_scelta = run_qt1; end
                2'b01:   begin p_scelto = setup_price2; q_scelta = run_qt2; end
                2'b10:   begin p_scelto = setup_price3; q_scelta = run_qt3; end
                2'b11:   begin p_scelto = setup_price4; q_scelta = run_qt4; end
                default: begin p_scelto = 6'd0;         q_scelta = 6'd0;    end
            endcase
        end else begin
            p_scelto = 6'd0;
            q_scelta = 6'd0;
        end
    end

    // Controlli per autorizzare l'acquisto (Risposte SI/NO da mandare alla FSM)
    wire ok_prezzo         = (credito_reg >= p_scelto); // I soldi bastano?
    wire prod_disponibile  = (q_scelta > 0);            // Il prodotto c'è?
    wire coin_inserted     = coin[0] || coin[1] || coin[2];       // Qualsiasi tasto moneta
    wire selection_made    = selezione[0] || selezione[1] || selezione[2]; // Qualsiasi tasto prodotto
    wire available         = ok_prezzo && prod_disponibile;       // Tutto OK per erogare

    // 4. LOGICA SEQUENZIALE: Setup e Scatto della FSM
    // Tutto quello che succede in sincronia con il clock
    // Il setup finisce al ciclo 12. 12 in binario è 1100. 
    // Quindi se il bit 3 e il bit 2 sono a 1, abbiamo finito.
    assign setup_done = setup_count[3] && setup_count[2];

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            // Se premo reset, torno allo stato iniziale e azzero tutto
            state           <= SETUP;
            setup_count     <= 4'd0;
            setup_qt1       <= 6'd0; setup_price1 <= 6'd0;
            setup_qt2       <= 6'd0; setup_price2 <= 6'd0;
            setup_qt3       <= 6'd0; setup_price3 <= 6'd0;
            setup_qt4       <= 6'd0; setup_price4 <= 6'd0;
            setup_c01       <= 6'd0; setup_c02    <= 6'd0;
            setup_c05       <= 6'd0; setup_c10    <= 6'd0;
        end else begin
            // Altrimenti passo allo stato successivo deciso dalla FSM
            state <= next_state;
            
            // Fino a che il setup non è finito, smisto i dati in arrivo in base al contatore
            if (!setup_done) begin
                case (setup_count)
                    4'd0:  setup_qt1    <= {coin, selezione}; // Unisco i due cavi a 3 bit in un dato a 6 bit
                    4'd1:  setup_price1 <= {coin, selezione};
                    4'd2:  setup_qt2    <= {coin, selezione};
                    4'd3:  setup_price2 <= {coin, selezione};
                    4'd4:  setup_qt3    <= {coin, selezione};
                    4'd5:  setup_price3 <= {coin, selezione};
                    4'd6:  setup_qt4    <= {coin, selezione};
                    4'd7:  setup_price4 <= {coin, selezione};
                    4'd8:  setup_c01    <= {coin, selezione};
                    4'd9:  setup_c02    <= {coin, selezione};
                    4'd10: setup_c05    <= {coin, selezione};
                    4'd11: setup_c10    <= {coin, selezione};
                endcase
                setup_count <= setup_count + 1'b1; // Vado al dato successivo
            end
        end
    end

    // 5. TRANSIZIONI DELLA FSM (Come si muove la macchina)
    always @(*) begin
        next_state = state; // Di base, rimango nello stato in cui sono
        
        case (state)
            SETUP: begin
                if (setup_done) next_state = IDLE;
            end
            
            IDLE: begin
                if (annulla)           next_state = DISPENSE; // Sputa subito eventuali soldi 
                else if (coin_inserted)next_state = ACC_CREDIT;
            end
            
            ACC_CREDIT: begin
                if (annulla)           next_state = DISPENSE;
                else if (selection_made)next_state = SEL_PROD;
            end
            
            SEL_PROD: begin
                if (annulla)           next_state = DISPENSE;
                else if (conferma)     next_state = CHECK_AV;
            end
            
            CHECK_AV: begin
                if (available)         next_state = DISPENSE; // Tutto ok, eroga
                else                   next_state = ERROR;    // Manca qualcosa, errore
            end
            
            DISPENSE: begin
                next_state = IDLE; // Appena ho erogato, torno subito in attesa
            end
            
            ERROR: begin
                next_state = IDLE; // Mostro l'errore per un clock e torno in attesa
            end
            
            default: next_state = IDLE;
        endcase
    end

    // 6. GENERAZIONE COMANDI (Ritardati di un colpo di clock per sicurezza)
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            load_reg           <= 1'b0;
            eroga_reg          <= 1'b0;
            azzera_credito_reg <= 1'b0;
        end else begin
            // Alzo questi segnali solo se mi trovo nello stato giusto
            load_reg           <= (state == SETUP) && setup_done;
            eroga_reg          <= (state == DISPENSE);
            azzera_credito_reg <= (state == DISPENSE);
        end
    end

    // 7. CALCOLI E AGGIORNAMENTO DATI
    // Controlliamo quale prodotto esatto dobbiamo far scendere
    wire dispense_active = eroga_reg && !annulla && conferma;
    wire erogap1 = dispense_active && (selezione == 3'b100);
    wire erogap2 = dispense_active && (selezione == 3'b101);
    wire erogap3 = dispense_active && (selezione == 3'b110);
    wire erogap4 = dispense_active && (selezione == 3'b111);

    // Gestione del magazzino: se finisco il setup, carico le quantità iniziali. 
    // Altrimenti, se erogo, tolgo 1. Se no, lascio tutto com'è.
    wire [5:0] qt1_load = load_reg ? setup_qt1 : (erogap1 ? (run_qt1 - 1'b1) : run_qt1);
    wire [5:0] qt2_load = load_reg ? setup_qt2 : (erogap2 ? (run_qt2 - 1'b1) : run_qt2);
    wire [5:0] qt3_load = load_reg ? setup_qt3 : (erogap3 ? (run_qt3 - 1'b1) : run_qt3);
    wire [5:0] qt4_load = load_reg ? setup_qt4 : (erogap4 ? (run_qt4 - 1'b1) : run_qt4);

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            run_qt1 <= 6'd0; run_qt2 <= 6'd0; run_qt3 <= 6'd0; run_qt4 <= 6'd0;
        end else begin
            run_qt1 <= qt1_load;
            run_qt2 <= qt2_load;
            run_qt3 <= qt3_load;
            run_qt4 <= qt4_load;
        end
    end

    // Logica dei soldi (Credito e Resto)
    // Se premo annulla, il resto sono tutti i soldi che ho messo. Se compro, è credito - prezzo.
    wire [5:0] resto_raw = annulla ? credito_reg : (credito_reg - p_scelto);
    wire [5:0] calcolo_resto = eroga_reg ? resto_raw : 6'd0;
    
    // Il credito aumenta se metto monete, si azzera a fine transazione
    wire [5:0] calcolo_credito = azzera_credito_reg ? 6'd0 : (credito_reg + valore_moneta);

    // Composizione dell'errore (Manca prodotto = bit 1, Manca soldi = bit 0)
    wire load_errore = conferma && (!ok_prezzo || !prod_disponibile);
    wire [1:0] codice_errore = {!prod_disponibile, !ok_prezzo};
    wire [1:0] calcolo_errore = azzera_credito_reg ? 2'b00 : (load_errore ? codice_errore : errore_reg);

    // Salvataggio dei calcoli nei Flip-Flop
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            credito_reg <= 6'd0;
            resto_reg   <= 6'd0;
            errore_reg  <= 2'b00;
        end else begin
            credito_reg <= calcolo_credito;
            resto_reg   <= calcolo_resto;
            errore_reg  <= calcolo_errore;
        end
    end

    // Ritardo di 1 clock per l'uscita fisica dei prodotti (così esce tutto pulito e stabile)
    reg prod1_out, prod2_out, prod3_out, prod4_out;
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            prod1_out <= 1'b0; prod2_out <= 1'b0; prod3_out <= 1'b0; prod4_out <= 1'b0;
        end else begin
            prod1_out <= erogap1; prod2_out <= erogap2; prod3_out <= erogap3; prod4_out <= erogap4;
        end
    end

    // 8. USCITE GLOBALI (Collegamento dei cavi verso l'esterno)
    assign credito    = credito_reg;
    assign resto      = resto_reg;
    assign errore     = errore_reg;
    
    assign prodotto1  = prod1_out;
    assign prodotto2  = prod2_out;
    assign prodotto3  = prod3_out;
    assign prodotto4  = prod4_out;

    // Calcolo della cassa totale pesando le quantità di monete per il loro valore
    assign disponibile = setup_c01 + (setup_c02 * 2'd2) + (setup_c05 * 3'd5) + (setup_c10 * 4'd10) + credito_reg;

endmodule