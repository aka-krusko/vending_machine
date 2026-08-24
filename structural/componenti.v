// LIBRERIA DI BASE
// Flip-Flop
module ff (
    input clk,
    input rst,
    input d,
    output reg q
);

    always @(posedge clk or negedge rst) begin
        if (!rst) 
            q <= 1'b0;
        else
            q <= d;
    end
endmodule

// Half Adder
module half_adder (
    input a, b,
    output sum, cout
);
    xor(sum, a, b);
    and(cout, a, b);
endmodule


// Registro a 6 bit
module registro (
    input clk,
    input rst,
    input enable,
    input [5:0] d,
    output [5:0] q
);
    wire [5:0] d_next;

    genvar i;
    generate
        for(i = 0; i < 6; i = i + 1) begin : registro
        // se enable 1 = d[i] altrimenti mantiene il valore attuale di q[i]
        mux2 mux_en (.d0(q[i]), .d1(d[i]), .sel(enable), .y(d_next[i]));
        ff ffd (.d(d_next[i]), .clk(clk), .rst(rst), .q(q[i]));
        end
    endgenerate
endmodule

// Decoder 4 a 12
module decoder (
    input [3:0] in,
    output [11:0] out
);
    wire a, b, c, d;

    // Negazione degli ingressi
    not(d, in[0]);
    not(c, in[1]);
    not(b, in[2]);
    not(a, in[3]);

    // Decodifica delle 12 combinazioni
    genvar i;
    generate
        for(i = 0; i < 12; i = i + 1) begin : andports
        // istanzia 12 porte and
        // (i & mask) valuta il singolo bit dell'indice i
        // bit a 1 collego in, bit a 0 collego a, b, c, d
            and(
                out[i],
                (i & 8) ? in[3] : a,    // 4° bit
                (i & 4) ? in[2] : b,    // 3° bit
                (i & 2) ? in[1] : c,    // 2° bit
                (i & 1) ? in[0] : d     // 1° bit
            );
        end
    endgenerate
endmodule

// Counter a 4 bit (parametrico)
module counter #(parameter N = 4) (
    input clk,
    input rst,
    input enable,
    output [N-1:0] count
);

    wire [N-1:0] next_count;
    wire [N-1:0] sum_out;
    wire [N:0] cout;

    genvar i;
    generate
        for(i = 0; i < N; i = i + 1) begin : counter12
            // 1. Generazione della catenda di half-adder
                if (i == 0) begin: ha_first
                // primo bit somma sempre 1
                    half_adder ha (.a(count[i]), .b(1'b1), .sum(sum_out[i]), .cout(cout[i+1]));
                end else begin : ha_rest
                // i bit successivi sommano il riporto del bit precedente
                    half_adder ha (.a(count[i]), .b(cout[i]), .sum(sum_out[i]), .cout(cout[i+1]));
                end

            // 2. Generazione del mux per l'enable
            mux2 #(.WIDTH(1)) mux_count (.d0(count[i]), .d1(sum_out[i]), .sel(enable), .y(next_count[i]));
            // 3. Generazione del flip flop
            ff ff_count (.d(next_count[i]), .clk(clk), .rst(rst), .q(count[i]));
        end
    endgenerate
endmodule

// Full Adder a 1 bit
module full_adder (
    input a, b, cin,
    output sum, cout
);

    wire entrance, exit, exit1;
    half_adder ha1 (.a(a), .b(b), .sum(entrance), .cout(exit));
    half_adder ha2 (.a(entrance), .b(cin), .sum(sum), .cout(exit1));
    or (cout, exit, exit1);
endmodule

// Ripple Carry Adder a 6 bit
module adder_6bit (
    input [5:0] a, b,
    input cin,
    output [5:0] sum,
    output cout
);
    wire c1, c2, c3, c4, c5;

    full_adder fa0 (.a(a[0]), .b(b[0]), .cin(cin), .sum(sum[0]), .cout(c1));
    full_adder fa1 (.a(a[1]), .b(b[1]), .cin(c1), .sum(sum[1]), .cout(c2));
    full_adder fa2 (.a(a[2]), .b(b[2]), .cin(c2), .sum(sum[2]), .cout(c3));
    full_adder fa3 (.a(a[3]), .b(b[3]), .cin(c3), .sum(sum[3]), .cout(c4));
    full_adder fa4 (.a(a[4]), .b(b[4]), .cin(c4), .sum(sum[4]), .cout(c5));
    full_adder fa5 (.a(a[5]), .b(b[5]), .cin(c5), .sum(sum[5]), .cout(cout));
endmodule

// Comparatori
// A > 0
module greater_than_zero (
    input [5:0] a,
    output greater
);
    or (greater, a[0], a[1], a[2], a[3], a[4], a[5]);
endmodule

// A >= B
module greater_equal (
    input [5:0] a, b,
    output ge
);
    wire [5:0] notb,sum_dummy;
    assign notb = ~b;

    adder_6bit sub (
        .a(a),
        .b(notb),
        .cin(1'b1),
        .sum(sum_dummy),
        .cout(ge)
    );
endmodule

// MUX
module mux2 #(parameter WIDTH = 1) (
    input [WIDTH-1:0] d0,
    input [WIDTH-1:0] d1,
    input sel,
    output [WIDTH-1:0] y
);
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : mux
            wire not_sel, w_d0, w_d1;
            
            not (not_sel, sel);
            and (w_d0, d0[i], not_sel);
            and (w_d1, d1[i], sel);

            or (y[i], w_d0, w_d1);
        end
    endgenerate
endmodule

module mux4 #(parameter WIDTH = 1) (
    input [WIDTH-1:0] d0,
    input [WIDTH-1:0] d1,
    input [WIDTH-1:0] d2,
    input [WIDTH-1:0] d3,
    input [1:0] sel,
    output [WIDTH-1:0] y
);
    wire [WIDTH-1:0] w1, w2;

    mux2 #(.WIDTH(WIDTH)) lower (.d0(d0), .d1(d1), .sel(sel[0]), .y(w1));
    mux2 #(.WIDTH(WIDTH)) upper (.d0(d2), .d1(d3), .sel(sel[0]), .y(w2));
    mux2 #(.WIDTH(WIDTH)) final (.d0(w1), .d1(w2), .sel(sel[1]), .y(y));
endmodule