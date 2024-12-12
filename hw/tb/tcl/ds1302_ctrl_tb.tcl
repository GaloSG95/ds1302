restart -f -nowave
config wave -signalnamewidth 1

add wave clk
add wave rst
add wave sclk 
add wave ce   
add wave io_buff
add wave start   
add wave rw     
add wave addr    
add wave din     
add wave dout    
add wave dvalid  
add wave busy    

add wave -divider internal
add wave uut/ds1302_ctrl_inst/state

run -all

view signals wave