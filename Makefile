$?ALCHEMY:=/path/to/alchemy/SDK

all:
	@mkdir -p install/usr/lib
	@mkdir -p install/usr/include
	
	@echo "Compiling libGL.as"
	@java -jar $(ALCHEMY)/usr/lib/asc.jar -md -strict -abcfuture -AS3 \
	-import $(ALCHEMY)/usr/lib/builtin.abc \
	-import $(ALCHEMY)/usr/lib/playerglobal.abc \
	-import $(ALCHEMY)/usr/lib/BinaryData.abc \
	-import $(ALCHEMY)/usr/lib/C_Run.abc \
	-import $(ALCHEMY)/usr/lib/CModule.abc \
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
	@$(ALCHEMY)/usr/bin/g++ -fno-exceptions -O4 -c -Iinstall/usr/include/ libGL.cpp
	@$(ALCHEMY)/usr/bin/ar crus install/usr/lib/libGL.a install/usr/lib/libGL.abc libGL.o 

	@rm -f libGL.o 
