/* -*- P4_16 -*- */

/*
 * P4 Wordle
 *
 * This program implements a simple protocol. It can be carried over Ethernet
 * (Ethertype 0x1234).
 *
 * The Protocol header looks like this:
 *
 * States: 
 * - 0 -> Unchecked
 * - 1 -> No Used
 * - 2 -> Wrong Place
 * - 3 -> Right Place
 *
 * Packet Format:
 * 
 * WORDLE (6*8 = 48 bits)
 * Current_Guess (5*8 = 40 bits)
 * 1st Word (5*8 = 40 bits)
 * 1st Word State (5*2 = 10 bits) (Use 12 bits because it is difficult to define 10bits in hex)
 * 2nd Word (5*8 = 40 bits)
 * 2nd Word State (5*2 = 10 bits)
 * 3rd Word (5*8 = 40 bits)
 * 3rd Word State (5*2 = 10 bits)
 * 4th Word (5*8 = 40 bits)
 * 4th Word State (5*2 = 10 bits)
 * 5th Word (5*8 = 40 bits)
 * 5th Word State (5*2 = 10 bits)
 * 6th Word (5*8 = 40 bits)
 * 6th Word State (5*2 = 10 bits)
 * 
 * The device receives a packet, performs the check on the current word, returns outcome
 *
 * If an unknown operation is specified or the header is not valid, the packet
 * is dropped
 */


/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

/*
 * Define the headers the program will recognize
 */

/*
 * Standard Ethernet header
 */
header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

/*
 * This is a custom protocol header for the calculator. We'll use
 * etherType 0x1234 for it (see parser)
 */
const bit<16> P4WORDLE_ETYPE = 0x1234;
const bit<48> P4WORDLE_HEADER = 0x574f52444c45;
const bit<40> P4WORDLE_TEST_WORD = 0x524f555445;

header p4wordle_t {

   bit<48> wordle;
   
   bit<40> guess;
   
   bit<16> outcome;
   
}

/*
 * All headers, used in the program needs to be assembled into a single struct.
 * We only need to declare the type, but there is no need to instantiate it,
 * because it is done "by the architecture", i.e. outside of P4 functions
 */
struct headers {
    ethernet_t   ethernet;
    p4wordle_t   p4wordle;
}

/*
 * All metadata, globally used in the program, also  needs to be assembled
 * into a single struct. As in the case of the headers, we only need to
 * declare the type, but there is no need to instantiate it,
 * because it is done "by the architecture", i.e. outside of P4 functions
 */

struct metadata {
    /* In our case it is empty */
}

/*************************************************************************
 ***********************  P A R S E R  ***********************************
 *************************************************************************/
parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {
    state start {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            P4WORDLE_ETYPE : check_p4wordle;
            default      : accept;
        }
    }

    state check_p4wordle {
        
        transition select(packet.lookahead<p4wordle_t>().wordle) {
            (P4WORDLE_HEADER) : parse_p4wordle;
            default           : accept;
        }
        
    }

    state parse_p4wordle {
        packet.extract(hdr.p4wordle);
        transition accept;
    }
}

/*************************************************************************
 ************   C H E C K S U M    V E R I F I C A T I O N   *************
 *************************************************************************/
control MyVerifyChecksum(inout headers hdr,
                         inout metadata meta) {
    apply { }
}






/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {
    
    action state_machine(bit<16> input){
        hdr.p4wordle.outcome = hdr.p4wordle.outcome | input;
    }

    action send_forward(){
         bit<48> tmp;
         tmp = hdr.ethernet.dstAddr;
         hdr.ethernet.dstAddr = hdr.ethernet.srcAddr;
         hdr.ethernet.srcAddr = tmp;
         standard_metadata.egress_spec = standard_metadata.ingress_port;
    }


    action operation_drop() {
        mark_to_drop(standard_metadata);
    }
    
    
    table operation_char_1 {
    	key = {
            hdr.p4wordle.guess[7:0]  : exact;
        }
		actions = {
            send_forward;
            state_machine;
            operation_drop;
        }
        const default_action = operation_drop();
        
        const entries = {
            P4WORDLE_TEST_WORD[7:0] : state_machine(0xc000);
            P4WORDLE_TEST_WORD[15:8] : state_machine(0x4000);
            P4WORDLE_TEST_WORD[23:16] : state_machine(0x4000);
            P4WORDLE_TEST_WORD[31:24] : state_machine(0x4000);
            P4WORDLE_TEST_WORD[39:32] : state_machine(0x4000);
        }
    }

    table operation_char_2 {
    	key = {
            hdr.p4wordle.guess[15:8]  : exact;
        }
		actions = {
            send_forward;
            state_machine;
            operation_drop;
        }
        const default_action = operation_drop();
        
        const entries = {
            P4WORDLE_TEST_WORD[7:0] : state_machine(0x1000);
            P4WORDLE_TEST_WORD[15:8] : state_machine(0x3000);
            P4WORDLE_TEST_WORD[23:16] : state_machine(0x1000);
            P4WORDLE_TEST_WORD[31:24] : state_machine(0x1000);
            P4WORDLE_TEST_WORD[39:32] : state_machine(0x1000);
        }
    }

    table operation_char_3 {
    	key = {
            hdr.p4wordle.guess[23:16]  : exact;
        }
		actions = {
            send_forward;
            state_machine;
            operation_drop;
        }
        const default_action = operation_drop();
        
        const entries = {
            P4WORDLE_TEST_WORD[7:0] : state_machine(0x0400);
            P4WORDLE_TEST_WORD[15:8] : state_machine(0x0400);
            P4WORDLE_TEST_WORD[23:16] : state_machine(0x0c00);
            P4WORDLE_TEST_WORD[31:24] : state_machine(0x0400);
            P4WORDLE_TEST_WORD[39:32] : state_machine(0x0400);
        }
    }

    table operation_char_4 {
    	key = {
            hdr.p4wordle.guess[31:24]  : exact;
        }
		actions = {
            send_forward;
            state_machine;
            operation_drop;
        }
        const default_action = operation_drop();
        
        const entries = {
            P4WORDLE_TEST_WORD[7:0] : state_machine(0x0100);
            P4WORDLE_TEST_WORD[15:8] : state_machine(0x0100);
            P4WORDLE_TEST_WORD[23:16] : state_machine(0x0100);
            P4WORDLE_TEST_WORD[31:24] : state_machine(0x0300);
            P4WORDLE_TEST_WORD[39:32] : state_machine(0x0100);
        }
    }

    table operation_char_5 {
    	key = {
            hdr.p4wordle.guess[39:32]  : exact;
        }
		actions = {
            send_forward;
            state_machine;
            operation_drop;
        }
        const default_action = operation_drop();
        
        const entries = {
            P4WORDLE_TEST_WORD[7:0] : state_machine(0x0040);
            P4WORDLE_TEST_WORD[15:8] : state_machine(0x0040);
            P4WORDLE_TEST_WORD[23:16] : state_machine(0x0040);
            P4WORDLE_TEST_WORD[31:24] : state_machine(0x0040);
            P4WORDLE_TEST_WORD[39:32] : state_machine(0x00c0);
        }
    }

    apply {
        if (hdr.p4wordle.isValid()) {
            operation_char_1.apply();
            operation_char_2.apply();
            operation_char_3.apply();
            operation_char_4.apply();
            operation_char_5.apply();
            send_forward();
        } 
        else {
            operation_drop();
        }
    }
}

/*************************************************************************
 ****************  E G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    apply { }
}

/*************************************************************************
 *************   C H E C K S U M    C O M P U T A T I O N   **************
 *************************************************************************/

control MyComputeChecksum(inout headers hdr, inout metadata meta) {
    apply { }
}

/*************************************************************************
 ***********************  D E P A R S E R  *******************************
 *************************************************************************/
control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.p4wordle);
    }
}

/*************************************************************************
 ***********************  S W I T T C H **********************************
 *************************************************************************/

V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;
