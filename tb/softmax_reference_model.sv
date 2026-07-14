`ifndef SOFTMAX_REFERENCE_MODEL_SV
`define SOFTMAX_REFERENCE_MODEL_SV

class softmax_reference_model extends uvm_component;

    `uvm_component_utils(softmax_reference_model)

    uvm_analysis_imp #(
        softmax_transaction,
        softmax_reference_model
    ) input_imp; 

    uvm_analysis_port #(
        softmax_transaction
    ) expected_ap;

    function new(
        string name = "softmax_reference_model",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        input_imp   = new("input_imp", this);
        expected_ap = new("expected_ap", this);
    endfunction

    function real fixed_to_real(
        logic signed [DATA_WIDTH-1:0] fixed_value
    );
        real scale;

        scale = 2.0 ** FRACTIONAL_BITS;

        return real'($signed(fixed_value)) / scale;
    endfunction

    function logic [DATA_WIDTH-1:0] probability_to_fixed(
        real value
    );
        real scale;
        longint signed quantized;

        scale = 2.0 ** FRACTIONAL_BITS;

        quantized = $rtoi(value * scale + 0.5);

        if (quantized < 0)
            quantized = 0;

        return quantized[DATA_WIDTH-1:0];
    endfunction

    function void write(softmax_transaction input_tr);
        softmax_transaction expected_tr;

        real input_real [NUM_ELEMENTS];
        real exp_real   [NUM_ELEMENTS];

        real maximum;
        real sum;
        real softmax_value;

        foreach (input_tr.data_in[i]) begin
            if ($isunknown(input_tr.data_in[i])) begin
                `uvm_error(
                    "REFMODEL_X",
                    $sformatf(
                        "data_in[%0d] contains X or Z",
                        i
                    )
                )
                return;
            end
        end

        foreach (input_tr.data_in[i]) begin
            input_real[i] =
                fixed_to_real(input_tr.data_in[i]);
        end

        maximum = input_real[0];

        foreach (input_real[i]) begin
            if (input_real[i] > maximum)
                maximum = input_real[i];
        end

        sum = 0.0;

        foreach (input_real[i]) begin
            exp_real[i] = $exp(input_real[i] - maximum);
            sum += exp_real[i];
        end

        if (sum <= 0.0) begin
            `uvm_error(
                "REFMODEL_SUM",
                "Softmax exponential sum is not positive"
            )
            return;
        end

        expected_tr =
            softmax_transaction::type_id::create("expected_tr");

        expected_tr.op                = op_normal;
        expected_tr.rst_n             = input_tr.rst_n;
        expected_tr.data_in           = input_tr.data_in;
        expected_tr.softmax_array_out = '0;

        foreach (exp_real[i]) begin
            softmax_value = exp_real[i] / sum;

            expected_tr.softmax_array_out[
                i*DATA_WIDTH +: DATA_WIDTH
            ] = probability_to_fixed(softmax_value);
        end

        expected_ap.write(expected_tr);

        `uvm_info(
            "REFMODEL",
            $sformatf(
                "Generated expected Softmax result:\n%s",
                expected_tr.sprint()
            ),
            UVM_HIGH
        )
    endfunction

endclass

`endif