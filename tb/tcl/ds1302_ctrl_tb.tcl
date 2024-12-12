restart -f -nowave
config wave -signalnamewidth 1

add wave clk
add wave rst
add wave sclk 
add wave ce   

add wave i_buff
add wave o_buff
add wave t_buff

add wave start   
add wave rw     
add wave addr    
add wave din     
add wave dout    
add wave dvalid  
add wave busy    

add wave -divider internal
add wave -radix unsigned uut/state_machine/bit_counter
add wave uut/state_machine/message
add wave uut/state

add wave -divider
add wave data_verification_proc/rmessage
add wave data_verification_proc/command

run -all

view signals wave