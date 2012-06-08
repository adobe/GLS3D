$?ALCHEMY:=/path/to/alchemy/SDK

all:
	@mkdir -p install/usr/lib
	@mkdir -p install/usr/include
	
	@echo "Compiling libGL.as"
	@java -classpath $(ALCHEMY)/usr/lib/asc.jar macromedia.asc.embedding.ScriptCompiler -optimize -strict -abcfuture -AS3 \
	-import $(ALCHEMY)/usr/lib/builtin.abc \
	-import $(ALCHEMY)/usr/lib/playerglobal.abc \
	-import $(ALCHEMY)/usr/lib/BinaryData.abc \
	-import $(ALCHEMY)/usr/lib/C_Run.abc \
	-import $(ALCHEMY)/usr/lib/CModule.abc \
	src/com/adobe/utils/AGALMacroAssembler.as \
	src/com/adobe/utils/AGALMiniAssembler.as \
	src/com/adobe/utils/FractalGeometryGenerator.as \
	src/com/adobe/utils/PerspectiveMatrix3D.as \
	src/com/adobe/utils/macro/AGALPreAssembler.as \
	src/com/adobe/utils/macro/AGALVar.as \
	src/com/adobe/utils/macro/BinaryExpression.as \
	src/com/adobe/utils/macro/Expression.as \
	src/com/adobe/utils/macro/ExpressionParser.as \
	src/com/adobe/utils/macro/NumberExpression.as \
	src/com/adobe/utils/macro/UnaryExpression.as \
	src/com/adobe/utils/macro/VariableExpression.as \
	src/com/adobe/utils/macro/VM.as \
	libGL.as -outdir . -out libGL
	@mv libGL.abc install/usr/lib/libGL.abc

	@echo "Compiling libGL.cpp"
	@$(ALCHEMY)/usr/bin/g++ -fno-exceptions -O4 -c -Iinstall/usr/include/ libGL.cpp
	@$(ALCHEMY)/usr/bin/ar crus install/usr/lib/libGL.a libGL.o
	@rm libGL.o
