.data
 	input:		.space	40	#Space capible of storing 10 words, 40 characters
 	basePrompt:	.string	"Please enter the base of the number you are using (0 to exit): "
 	valuePrompt:	.string	"Please enter the value: "
 	invalidPrompt:	.string	"The value entered is not valid for the base entered"
 	outputPrompt:	.string "The given value in base 10 is: "
 
.macro exit
	li a7, 10					#Set syscall to exit program
	ecall						#Exit
.end_macro

.macro printInt(%x)					#x is the register with the int to print
	mv a0, %x					#Set syscall argument to the integer
	li a7, 1					#Set syscall argument to 1 (print integer)
	ecall
.end_macro

.macro printInti(%x)					#x is the register with the int to print, x is an immediate value
	addi a0, zero, %x				#Set syscall argument to the integer
	li a7, 1					#Set syscall argument to 1 (print integer)
	ecall
.end_macro

.macro readInt(%x)					#x is register to copy answer into
	li a7, 5					#Set syscall argument to 5 (read int from console)
	ecall
	mv %x, a0					#Place syscall rv into the given register
.end_macro
	
 .macro printChar(%x)					#x is char to print
	mv a0, %x					#Set syscall argument to print char
	li a7, 11					#Set syscall argument to 11 (print char)
	ecall
.end_macro

.macro printChari(%x)					#x is char to print, x is an immediate value
	addi a0, zero, %x				#Set syscall argument to print char
	li a7, 11					#Set syscall argument to 11 (print char)
	ecall
.end_macro
	
.macro println
	printChari(10)					#Print newline
.end_macro
	
.macro printString(%bufferAddr)				#Prints string to console
 	add a0, zero, %bufferAddr			#Copies buffer address to a0
 	li a7, 4					#Sets syscall to print null-terminated string
 	ecall
.end_macro
 
.macro printStringln(%bufferAddr)			#Prints string to console
 	add a0, zero, %bufferAddr			#Copies buffer address to a0
 	li a7, 4					#Sets syscall to print null-terminated string
 	ecall
 	println
.end_macro
 
.macro readString(%buffAddr, %numChars)			#Reads string from console
 	add a0, zero, %buffAddr				#Copies buffer address to a0
 	mv a1, %numChars				#Copies num chars to a1
 	li a7, 8					#Sets syscall to read string
 	ecall
.end_macro
 
.macro readStringi(%buffAddr, %numChars)		#Reads string from console, numchars is an immediate value
  	add a0, zero, %buffAddr				#Copies buffer address to a0
 	addi a1, zero, %numChars			#Copies num chars to a1
 	li a7, 8					#Sets syscall to read string
 	ecall
.end_macro
 		
.text
 	.globl main
 	main:
 		jal getBase
 		beqz a0, finished
 		mv s0, a0				#Save the base for later use
 		jal getValue
 		mv a2, s0				#Set function argument
 		jal translateValue
	 	beqz a1, errorMessage			#If there was an error, print error message
	 		mv a2, a0			#Set function argument
 			jal printResult
 			j noErrorMessageEnd
	 	errorMessage:
 			jal printErrorMessage
 		noErrorMessageEnd:
 		println
	 	j main 		
 		finished:
	 		exit
 		
 	#a0:	base of the number, limited to 0,2-36
 	getBase:
 		add a0, zero, zero			#Set rv to 0
 		lui t0, %hi(basePrompt)			#Load the address of base prompt
 		addi t0, t0, %lo(basePrompt)
 		li t1, 1				#Set the lower bound
 		li t2, 37				#Set the upper bound
 		getBaseLoop:
 			printString(t0)
 			readInt(a0)
 			beqz a0, getBaseLoopEnd		#If 0, exit
 			bge a0, t2, getBaseLoop		#If >37, loop again
 			ble a0, t1, getBaseLoop		#If <2, loop again
 		getBaseLoopEnd:
 		jr ra
 			
  	getValue:
  		lui t0, %hi(valuePrompt)		#Load the address of value prompt
 		addi t0, t0, %lo(valuePrompt)
 		printString(t0)
 		lui t0, %hi(input)			#Load the address to store the data
 		addi t0, t0, %lo(input)
 		readStringi(t0,40)
 		jr ra
 		
 	printResult:
 		lui t0, %hi(outputPrompt)		#Load the address of output prompt
 		addi t0, t0, %lo(outputPrompt)
 		printString(t0)
 		printInt(a2)
 		println
 		jr ra
 		
 	printErrorMessage:
 		lui t0, %hi(invalidPrompt)		#Load the address of output prompt
 		addi t0, t0, %lo(invalidPrompt)
 		printStringln(t0)
 		jr ra
 		
 	#a2:	base of the number to translate
 	#a0:	number in base 10
 	#a1:	0 for error, 1 for no error
 	translateValue:
 		addi sp, sp, -4						#Subtract 4 from sp
 		sw ra, 0(sp)						#Store ra
 		mv s0, a2						#Save base for later
 		lui s1, %hi(input)					#Load the address of base prompt
 		addi s1, s1, %lo(input)
 		mv a2, s1						#Copy address for function call
 		jal strlen
 		mv s2, a0						#Save the strlen for later
 		add s3, zero, zero					#Initilize loop counter to 0
 		add s4, zero, zero					#Initilize rv to 0
 		add s6, zero, zero					#Initilize negative flag (0=positive, 1=negative)
 		li a1, 1						#Initilize rv2 to 1
 		translateValueLoop:
 			add a2, s1, s3					#Calculate address of char
 			lb a2, 0(a2)					#Load char from memory
 			
 			addi t0, zero, '-'				#Set dash value
 			bne a2, t0, nonNegative				#If a negative symbol is found set the negative flag
 			bne a6, zero, nonNegative			#If a negative symbol has already been found, attempt to translate
 				bne s3, zero, translateValueInvalid	#If a negative symbol is found after the first char, invalid
 				addi s6, zero, 1			#Set negative flag to 1
 				j translationAttemptEnd
 			nonNegative:
 				jal translateFromASCII
 				mv s5, a0				#Save value for later
 				bge s5, s0, translateValueInvalid	#If value >=base value, invalid number
 				blt s5, zero, translateValueInvalid	#If value <0, invalid number
 				mv a2, s0				#Set base for func call
 				sub a3, s2, s3				#Set power for func call
 				addi a3, a3, -1				#Sub 1 so pow is correct
 				jal pow
 				mul s5, s5, a0				#Multiply the power by the base
 				add s4, s4, s5				#Add result to rv
 			translationAttemptEnd:
 				addi s3, s3, 1				#Increment loop counter
 				bne s3, s2, translateValueLoop		#If counter!=strlen, loop again
 			j translateValueEnd
 		translateValueInvalid:
 			add a1, zero, zero				#Set the error flag
 		translateValueEnd:
 			beq s6, zero, dontNegate			#If the negative flag is not set, don't negate
 				addi t0, zero, -1			#Set value to be -1
 				mul s4, s4, t0				#Multiply by -1
 			dontNegate:
 			mv a0, s4
 			lw ra, 0(sp)					#Restore ra
			addi sp, sp, 4					#Increment sp
			jr ra	
 		
 	#a2:	address of string
 	#a0:	length of string (excluding \n)
 	strlen:
 		li a0, -1				#Set rv to 0
 		li t1, 10				#Set newline char
 		strlenLoop:
 			addi a0, a0, 1			#Increment rv
 			lb t0, 0(a2)			#Get char
 			addi a2, a2, 1			#Increment to get next char
 			bne t0, t1, strlenLoop		#If not \n, loop again
 		jr ra
 		
 	#a2:	base
 	#a3:	power
 	#a0:	result
 	pow:
 		li a0, 1				#Init rv
 		beqz a3, powEnd				#If power is 0, return 1
 		powLoop:
 			mul a0, a0, a2
 			addi a3, a3, -1			#Dincrement loop counter
 			bnez a3, powLoop		#If power!=0, loop again
 		powEnd:
	 		jr ra
 	
 	#a2:	ascii number to translate
 	#a0:	number value
 	translateFromASCII:
 		li t0, 9				#Set to 9
 		li t1, 26				#Set to 26
 		addi a0, a2, -48			#Subtract 48 to see if its 0-9
 		ble a0, t0, translateFromASCIIEnd	#If <=9, done
 		addi a0, a0, -17			#Subtract 17 more to see if its A-Z
 		ble a0, t1, translateFromASCIIAdd10	#If <=26, done
 		addi a0, a0, -32			#Subtract 32 more to see if its a-z
 		ble a0, t1, translateFromASCIIAdd10	#If <=26, done
 		translateFromASCIIAdd10:
 			addi a0, a0, 10			#Add 10 to adjust for A-Z being after 9
 		translateFromASCIIEnd:
 			jr ra
