module fsm (
    input clk,
    input rst,

    input setup_done,
    input [2:0] coin, selezione,
    input conferma, annulla,

    input ok_prezzo,
    input prod_disponibile,

    output load,
    output eroga,
    output azzera_credito
);

    // 1. Cavi di collegamento e registri di stato
    wire [2:0] state;
    wire [2:0] next_state;

    // Flip-Flop per memorizzare i 3 bit di stato
    ff ff_statebit0 (.d(next_state[0]), .clk(clk), .rst(rst), .q(state[0]));
    ff ff_statebit1 (.d(next_state[1]), .clk(clk), .rst(rst), .q(state[1]));
    ff ff_statebit2 (.d(next_state[2]), .clk(clk), .rst(rst), .q(state[2]));

    // 2. Decodifica dello stato attuale
    wire setup, idle, acc_credit, sel_prod, check_av, dispense, error;
    
    assign setup        = ~state[2] & ~state[1] & ~state[0];       // 000
    assign idle         = ~state[2] & ~state[1] &  state[0];       // 001
    assign acc_credit   = ~state[2] &  state[1] & ~state[0];       // 010
    assign sel_prod     = ~state[2] &  state[1] &  state[0];       // 011
    assign check_av     =  state[2] & ~state[1] & ~state[0];       // 100
    assign dispense     =  state[2] & ~state[1] &  state[0];       // 101
    assign error        =  state[2] &  state[1] & ~state[0];       // 110

    // 3. Condizionamento degli ingressi
    wire coin_wire, sel_wire, available;

    assign coin_wire = coin[0] | coin[1] | coin[2];
    assign sel_wire = selezione[0] | selezione[1] | selezione[2];

    // se ci sono entrambi i requisiti per procedere
    assign available = ok_prezzo & prod_disponibile;

    // 4. rete combinatoria del prossimo stato
    wire not_setup, 
         not_idle, 
         not_acc_credit, 
         not_sel_prod, 
         not_check_av, 
         not_dispense, 
         not_error;
    
    // SETUP
    assign not_setup = setup & ~setup_done;

    // IDLE
    assign not_idle = (setup & setup_done) |
                      (idle & ~coin_wire & ~annulla) |
                      (dispense) | // clock successivo a dispense ritorna in idle
                      error;       // clock successivo a error torna in idle

    // ACC_CREDIT
    assign not_acc_credit = (idle & coin_wire) |
                            (acc_credit & ~sel_wire & ~annulla);

    // SEL_PROD
    assign not_sel_prod = (acc_credit & sel_wire) |
                          (sel_prod & ~conferma & ~annulla);

    // CHECK_AV
    assign not_check_av = sel_prod & conferma;

    // DISPENSE
    assign not_dispense = (idle & annulla) |
                          (acc_credit & annulla) |
                          (sel_prod & annulla) |
                          (check_av & available);

    // ERROR
    assign not_error = check_av & ~available;

    // Ricodifica per i flip-flop del prossimo stato
    assign next_state[0] = not_idle | not_sel_prod | not_dispense;
    assign next_state[1] = not_acc_credit | not_sel_prod | not_error;
    assign next_state[2] = not_check_av | not_dispense | not_error;

    // 5. Registri di uscita
    wire next_load, next_eroga, next_azzera;

    // logica combinatoria per le uscite
    assign next_load = setup & setup_done;
    assign next_eroga = dispense;
    assign next_azzera = dispense;

    ff ff_load (.d(next_load), .clk(clk), .rst(rst), .q(load));
    ff ff_eroga (.d(next_eroga), .clk(clk), .rst(rst), .q(eroga));
    ff ff_azzera (.d(next_azzera), .clk(clk), .rst(rst), .q(azzera_credito));

endmodule