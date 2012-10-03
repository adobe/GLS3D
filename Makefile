$?FLASCC:=/path/to/FLASCC/SDK

all:
	@mkdir -p install/usr/lib
	@mkdir -p install/usr/include
	
	@echo "Compiling libGL.as"
	@java -jar $(FLASCC)/usr/lib/asc2.jar -md -strict -optimize -AS3 \
	-import $(FLASCC)/usr/lib/builtin.abc \
	-import $(FLASCC)/usr/lib/playerglobal.abc \
	-import $(FLASCC)/usr/lib/BinaryData.abc \
	-import $(FLASCC)/usr/lib/C_Run.abc \
	-import $(FLASCC)/usr/lib/CModule.abc \
	-in src/com/adobe/utils/AGALMiniAssembler.as \
	-in src/com/adobe/utils/AGALMacroAssembler.as \
	-in src/com/adobe/utils/FractalGeometryGenerator.as \
	-in src/com/adobe/utils/PerspectiveMatrix3D.as \
	-in src/com/adobe/utils/macro/AGALPreAssembler.as \
	-in src/com/adobe/utils/macro/AGALVar.as \
	-in src/com/adobe/utils/macro/Expression.as \
	-in src/com/adobe/utils/macro/BinaryExpression.as \
	-in src/com/adobe/utils/macro/ExpressionParser.as \
	-in src/com/adobe/utils/macro/NumberExpression.as \
	-in src/com/adobe/utils/macro/UnaryExpression.as \
	-in src/com/adobe/utils/macro/VariableExpression.as \
	-in src/com/adobe/utils/macro/VM.as \
	libGL.as
	@mv libGL.abc install/usr/lib/
	
	@echo "Compiling libGL.cpp"
	@$(FLASCC)/usr/bin/g++ -fno-exceptions -O4 -c -Iinstall/usr/include/ libGL.cpp
	@$(FLASCC)/usr/bin/ar crus install/usr/lib/libGL.a install/usr/lib/libGL.abc libGL.o 

	@rm -f libGL.o 
