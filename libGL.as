/*
Copyright (c) 2012, Adobe Systems Incorporated
All rights reserved.

Redistribution and use in source and binary forms, with or without 
modification, are permitted provided that the following conditions are
met:

* Redistributions of source code must retain the above copyright notice, 
this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the 
documentation and/or other materials provided with the distribution.

* Neither the name of Adobe Systems Incorporated nor the names of its 
contributors may be used to endorse or promote products derived from 
this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR 
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

package Stage3DGL
{
    import com.adobe.utils.*;
    import com.adobe.utils.macro.*;
    import com.adobe.alchemy.CModule;
    
    import flash.display.*;
    import flash.display3D.*;
    import flash.display3D.textures.*;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.events.TextEvent;
    import flash.geom.*;
    import flash.text.TextField;
    import flash.text.TextFieldType;
    import flash.trace.Trace;
    import flash.utils.*;

    public class GLAPI
    {   

        // -------------------------------------------------------------------
        // Debug console
        
        private var lsitDisabled:Dictionary = new Dictionary()
        private var texturesShown:Dictionary = new Dictionary()
        private var bgColorOverride:Boolean = false
        private var overrideR:uint
        private var overrideG:uint
        private var overrideB:uint
        private const overrideA:uint = 0xFF

        public var disableCulling:Boolean = false
        public var disableBlending:Boolean = false
        
        private var _stage:Stage

        private var debugUI:Sprite
        private var console:TextField
        private var consoleInput:TextField
        private function createDebugUI():void
        {
            // Main Panel
            debugUI = new Sprite()
            debugUI.graphics.lineStyle(2, 0xFF0000)
            debugUI.graphics.beginFill(0xFF0000, 0.2)
            debugUI.graphics.drawRect(0, 0, 1000, 350)
            debugUI.graphics.endFill()
            
            console = new TextField()
            console.wordWrap = true
            console.width = 900
            console.height = 300
            console.x = 50
            console.y = 10
            console.selectable = true
            console.text = "--------------"
            debugUI.addChild(console)

            var prompt:TextField = new TextField()
            prompt.x = 50
            prompt.y = 320
            prompt.height = 14
            prompt.text = ">"
            debugUI.addChild(prompt)
            
            consoleInput = new TextField()
            consoleInput.type = TextFieldType.INPUT
            consoleInput.x = 60
            consoleInput.y = 320
            consoleInput.height = 14
            consoleInput.width = 900
            consoleInput.text = ""
            consoleInput.multiline = true
            //consoleInput.addEventListener(flash.events.TextEvent.TEXT_INPUT, consoleInput_handler, false, 0, true)
            consoleInput.addEventListener(Event.CHANGE, consoleInput_changeHandler, false, 0, true)
            debugUI.addChild(consoleInput)
        }

        private function keyDown_handler(event:KeyboardEvent):void 
        {
            /*if (event.keyCode == 17) // shift 
            {
                var visible:Boolean = debugUI && debugUI.parent != null
                showConsole(!visible)
            }*/ 
        } 
        
        public function consoleInput_changeHandler(e:Event):void
        {
            var text:String = consoleInput.text
            // Did the user press "return"?
            var returnIndex:int = Math.max(text.indexOf("\n"), text.indexOf("\r"))
            if (returnIndex == -1)
                return
            
            var command:String = consoleInput.text
            console.appendText("\n > " + command)
            console.scrollV = console.maxScrollV
            consoleInput.text = ""
            processCommand(command)
        }
        
        public function consoleOut(value:String):void
        {
            if(console)
                console.appendText("\n" + value)
            trace(value)
        }
        
        public function processCommand(command:String):void
        {
            var args:Array = command.substr(0, command.length - 1).split(" ")
            switch (args[0])
            {
                case "": break
                case "show" : 
                    if (args.length >= 3) 
                        processShowCommand(args)
                    else
                        consoleOut("wrong args, expected more, for example \"show tex all\" or \"show tex 3\"")
                break
                case "hide" : 
                    if (args.length >= 3) 
                        processHideCommand(args)
                    else
                        consoleOut("wrong args, expected more, for example \"hide tex all\" or \"hide tex 3\"")
                break
                case "bgcolor" : 
                    if (args.length >= 2)
                        setClearColor(args)
                    else
                        consoleOut("wrong args, expected more, for example \"bgcolor 0x000000\" or \"bgcolor 0xFF\", (alpha is always 255)")
                break
                case "q3":
                    if(args[1] == "znear") {
                        CModule.write32(CModule.getPublicSym("q3_znear"), int(args[2]))
                    }
                    if(args[1] == "zfar") {
                        CModule.write32(CModule.getPublicSym("q3_zfar"), int(args[2]))
                    }
                    if(args[1] == "zneao") {
                        CModule.write32(CModule.getPublicSym("q3_znearo"), int(args[2]))
                    }
                    if(args[1] == "zfaro") {
                        CModule.write32(CModule.getPublicSym("q3_zfaro"), int(args[2]))
                    }
                    break
                case "log":
                    if (args.length >= 2)
                    {
                        if (args[1] == "on")
                        {
                            this.log = new TraceLog()
                        }
                        else if (args[1] == "off")
                        {
                            this.log = null
                        }
                        else
                            consoleOut("wrong args, expected for example \"log on \" or \"log off\"")
                    }
                    else
                        consoleOut("wrong args, expected more, for example \"log on \" or \"log off\"")
                break
                case "offset" :
                    if (args.length >= 2)
                    {
                        this.polygonOffsetValue = Number(args[1])
                        consoleOut("Setting polygonOffset to " + this.polygonOffsetValue)
                    }
                    else
                        consoleOut("wrong args, expected \"offset 0.1\" for example")
                break
                case "errorchecking":
                    if (args.length >= 2)
                    {
                        if (args[1] == "on")
                        {
                            //this.log = new TraceLog()
                            this.context.enableErrorChecking = true
                        }
                        else if (args[1] == "off")
                        {
                            this.context.enableErrorChecking = false
                        }
                        else
                            consoleOut("wrong args, expected for example \"errorchecking on \" or \"errorchecking off\"")
                    }
                    else
                        consoleOut("wrong args, expected more, for example \"errorchecking on \" or \"errorchecking off\"")
                    break
                case "help" :
                    consoleOut("------------------ HELP ------------------")
                    consoleOut("[show, hide] list [#, all] - show or hide specified gl command lists.")
                    consoleOut("[show, hide] tex [#, all] - show or hide specified debug textures.")
                    consoleOut("[show, hide] texlist [#, all] - show or hide debug textures associated with specified command list.")
                    consoleOut("bgcolor [set, clear] [hex color] - override current background color. \"clear\" will remove the override.")
                    consoleOut("log [on, off] turn logging on and off.")
                break
                default:
                    consoleOut("unknown command")
                break
            }
        }
        
        private function setClearColor(args:Array):void
        {
            switch (args[1])
            {
                case "clear": 
                    bgColorOverride = false
                    consoleOut("bgcolor cleared.")
                    break
                case "set":
                    bgColorOverride = true
                    var color:uint = args[2]
                    // useful info from: http://sierakowski.eu/list-of-tips/
                    overrideR = (color >> 16) & 0xFF
                    overrideG = (color >> 8) & 0xFF
                    overrideB = color & 0xFF
                    consoleOut("bgcolor set to " + color.toString(16))
                    break
                default:
                    consoleOut("Unknown bgcolor target " + args[1] + ", try [clear or set]")
            }
        }
        
        private function toggleAllTextures(show:Boolean):void
        {
            var count:int = texID - 1
            for (var i:int = 1; i <= count; i++)
            {
                texturesShown[i] = show
            }
        }
        
        private function toggleTexturesForList(id:int, show:Boolean):void
        {
            const cl:CommandList = commandLists[id]
            const count:int = cl.commands.length
            var command:Object
            for (var k:int = 0; k < count; k++)
            {
                command = cl.commands[k]
                var stateChange:ContextState = command as ContextState
                if (stateChange && stateChange.textureSamplers)
                {
                    // grab textures associated with this list.
                    for (var i:int = 0; i < 8; i++ )
                    {
                        var tID:int = stateChange.textureSamplers[i]
                        if (tID != -1)
                        {
                            texturesShown[tID] = show
                            consoleOut("texture " + tID + (show ? " shown" : " hidden"))
                        }
                    }
                }
            }
        }
        
        public function renderDebugHelpers():void
        {
            if (debugTexQuadID == -1)
            {
                debugTexQuadID = glGenLists(1)
                glNewList(debugTexQuadID, 0)
                glBegin(GL_QUADS)
                glTexCoord(0, 0)
                glColor(1, 0, 0, 1)
                glVertex(0, 0, 0)
                
                glTexCoord(1, 0)
                glColor(1, 0, 0, 1)
                glVertex(1, 0, 0)
                
                glTexCoord(1, 1)
                glColor(0, 0, 0, 1)
                glVertex(1, 1, 0)
                
                glTexCoord(0, 1)
                glColor(0, 1, 0, 1)
                glVertex(0, 1, 0)
                glEnd()
                glEndList()
            }
            
            var texPerRow:int = 15
            var w:Number = 1.8 / Number(texPerRow)
            var h:Number = w
            var x:Number = -0.9
            var y:Number = 0.5 - h
            
            var mStack:Vector.<Matrix3D> = modelViewStack
            var pStack:Vector.<Matrix3D> = projectionStack
            
            modelViewStack = new <Matrix3D>[ new Matrix3D()]
            projectionStack = new <Matrix3D>[ new Matrix3D()]
            
            glMatrixMode(GLAPI.GL_MODELVIEW)
            for (var i:int = 1; i < texID; i++)
            {
                if (texturesShown[i] != true)
                    continue
                glPushMatrix()
                glTranslate(x + Math.round(i % texPerRow) * (w + 0.02), y - Math.round(i / texPerRow) * (h + 0.02), 0)
                glScale(2 / texPerRow, 2 / texPerRow, 1)
                glBindTexture(GL_TEXTURE_2D, i)
                glCallList(debugTexQuadID)
                glPopMatrix()
            }
            
            modelViewStack = mStack
            projectionStack = pStack
            glMatrixMode(GLAPI.GL_MODELVIEW)
        }
        
        private function processHideCommand(args:Array):void
        {
            var i:int
            var id:int
            switch (args[1])
            {
                case "list" :
                    if (args[2] == "all")
                    {
                        var count:int = this.commandLists.length - 1
                        for (i = 0; i < count; i++)
                        {
                            lsitDisabled[i] = true
                        }
                        consoleOut("lists " + 0 + " through " + (count - 1) + " hidden")
                    }
                    else
                    {
                        id = args[2]
                        lsitDisabled[id] = true
                        consoleOut("list " + id + " hidden")
                    }
                    break
                
                case "tex" :
                    if (args[2] == "all")
                    {
                        toggleAllTextures(false)
                        consoleOut("textures " + 1 + " through " + (count) + " hidden")
                    }
                    else
                    {
                        id = args[2]
                        texturesShown[id] = false
                        consoleOut("texture " + id + " hidden")
                    }
                    break
                
                case "texlist" :
                    if (args[2] == "all")
                    {
                        toggleAllTextures(false)
                        consoleOut("textures " + 1 + " through " + (count) + " hidden")
                    }
                    else
                    {
                        var listid:int = args[2]
                        toggleTexturesForList(listid, false)
                    }
                break
                
                default:
                    consoleOut("Unknown hide target " + args[1] + ", try [list, texture, or txtlist]")
            }
        }

        private function processShowCommand(args:Array):void
        {
            var i:int
            var id:int
            switch (args[1])
            {
                case "list" :
                    if (args[2] == "all")
                    {
                        var count:int = this.commandLists.length - 1
                        for (i = 0; i < count; i++)
                        {
                            lsitDisabled[i] = false
                        }
                        consoleOut("lists " + 0 + " through " + (count - 1) + " shown")
                    }
                    else
                    {
                        id = args[2]
                        lsitDisabled[id] = false
                        consoleOut("list " + id + " shown")
                    }
                    break
                case "tex" :
                    if (args[2] == "all")
                    {
                        toggleAllTextures(true)
                        consoleOut("textures " + 1 + " through " + (count) + " shown")
                    }
                    else
                    {
                        id = args[2]
                        texturesShown[id] = true
                        consoleOut("texture " + id + " shown")
                    }
                    break
                
                case "texlist" :
                    if (args[2] == "all")
                    {
                        toggleAllTextures(true)
                        consoleOut("textures " + 1 + " through " + (count) + " shown")
                    }
                    else
                    {
                        var listid:int = args[2]
                        toggleTexturesForList(listid, true)
                    }
                    break
                
                default:
                    consoleOut("Unknown show target " + args[1] + ", try [list, texture, or txtlist]")
            }
        }

        public function showConsole(show:Boolean):void
        {
            if (!debugUI)
                createDebugUI()

            if (show && debugUI.parent == null)
            {
                _stage.addChildAt(debugUI, 0)
                debugUI.y = _stage.stageHeight - debugUI.height
                debugUI.x = _stage.stageWidth - debugUI.width
                _stage.focus = consoleInput
            }
            else if (!show && debugUI.parent != null)
            {
                _stage.removeChild(debugUI)
                _stage.focus = _stage
            }
        }
        
        public function get consoleOn():Boolean
        {
            return debugUI != null && debugUI.parent != null
        }
        
        // -------------------------------------------------------------------
        

        private static var _instance:GLAPI
        
        public static function init(context:Context3D, log:Object, stage:Stage):void
        {
            _instance = new GLAPI(context, log, stage)
            if (log) log.send("GLAPI initialized.")
        }
        
        public static function get instance():GLAPI
        {
            if (!_instance)
            {
                trace("Instance is null, did you forget calling GLAPI.init() in AlcConsole.as?") 
            }
            return _instance
        }
        
        public function send(value:String):void
        {
            if (log)
                log.send(value)
        }
        
        private var activeCommandList:CommandList = null
        private var commandLists:Vector.<CommandList> = null
        private var vbb:VertexBufferBuilder
        
        private function perspectiveProjection(fov:Number = 90,
                                                 aspect:Number = 1, 
                                                 near:Number = 1, 
                                                 far:Number = 2048):Matrix3D
        {
            var y2:Number = near * Math.tan(fov * Math.PI / 360)
            var y1:Number = -y2
            var x1:Number = y1 * aspect
            var x2:Number = y2 * aspect
            
            var a:Number = 2 * near / (x2 - x1)
            var b:Number = 2 * near / (y2 - y1)
            var c:Number = (x2 + x1) / (x2 - x1)
            var d:Number = (y2 + y1) / (y2 - y1)
            var q:Number = -(far + near) / (far - near)
            var qn:Number = -2 * (far * near) / (far - near)
            
            return new Matrix3D(Vector.<Number>([
                a, 0, 0, 0,
                0, b, 0, 0,
                c, d, q, -1,
                0, 0, qn, 0
            ]))
        }

        private function matrix3DToString(m:Matrix3D):String
        {
            var data:Vector.<Number> = m.rawData
            return ("[ " + data[0].toFixed(3) + ", " + data[4].toFixed(3) + ", " + data[8].toFixed(3) + ", " + data[12].toFixed(3) + " ]\n" +
                    "[ " + data[1].toFixed(3) + ", " + data[5].toFixed(3) + ", " + data[9].toFixed(3) + ", " + data[13].toFixed(3) + " ]\n" +
                    "[ " + data[2].toFixed(3) + ", " + data[6].toFixed(3) + ", " + data[10].toFixed(3) + ", " + data[14].toFixed(3) + " ]\n" +
                    "[ " + data[3].toFixed(3) + ", " + data[7].toFixed(3) + ", " + data[11].toFixed(3) + ", " + data[15].toFixed(3) + " ]")
        }
        
        // ======================================================================
        //  Polygon Offset
        // ----------------------------------------------------------------------
        
        /* polygon_offset */
        public static const GL_POLYGON_OFFSET_FACTOR:uint = 0x8038
        public static const GL_POLYGON_OFFSET_UNITS :uint = 0x2A00
        public static const GL_POLYGON_OFFSET_POINT :uint = 0x2A01
        public static const GL_POLYGON_OFFSET_LINE  :uint = 0x2A02
        public static const GL_POLYGON_OFFSET_FILL  :uint = 0x8037
        
        private var offsetFactor:Number = 0.0
        private var offsetUnits:Number = 0.0
            
        public function glPolygonMode(face:uint, mode:uint):void
        {
            switch(mode)
            {
                case GL_POINT:
                    if (log) log.send("glPolygonMode GL_POINT not yet implemented, mode is always GL_FILL.")
                    break
                case GL_LINE:
                    if (log) log.send("glPolygonMode GL_LINE not yet implemented, mode is always GL_FILL.")
                    break
                default:
                    // GL_FILL!
            }
        }
        
        public function glPolygonOffset(factor:Number, units:Number):void
        {
            offsetFactor = factor
            offsetUnits = units
            //if (log) log.send("glPolygonOffset() called with (" + factor + ", " + units + ")")
            if (log) log.send("glPolygonOffset() not yet implemented.")
        }

        public function glShadeModel(mode:uint):void
        {
            switch(mode)
            {
                case GL_FLAT:
                    if (log) log.send("glShadeModel GL_FLAT not yet implemented, mode is always GL_SMOOTH.")
                    break
                default:
                    // GL_SMOOTH!
            }
        }

        // ======================================================================
        //  Alpha Testing
        // ----------------------------------------------------------------------
        
        public function glAlphaFunc(func:uint, ref:Number):void
        {
            //TODO: fixme
        }
        
        // ======================================================================
        //  Lighting and Materials
        // ----------------------------------------------------------------------  
        
        public static const GL_LIGHTING                   :uint = 0x0B50
        public static const GL_LIGHT_MODEL_LOCAL_VIEWER   :uint = 0x0B51
        public static const GL_LIGHT_MODEL_TWO_SIDE       :uint = 0x0B52
        public static const GL_LIGHT_MODEL_AMBIENT        :uint = 0x0B53
        public static const GL_SHADE_MODEL                :uint = 0x0B54
        public static const GL_COLOR_MATERIAL_FACE        :uint = 0x0B55
        public static const GL_COLOR_MATERIAL_PARAMETER   :uint = 0x0B56
        public static const GL_COLOR_MATERIAL             :uint = 0x0B57
        public static const GL_MODELVIEW_MATRIX           :uint = 0x0BA6
        
        /* LightName */
        public static const GL_LIGHT0:uint = 0x4000
        public static const GL_LIGHT1:uint = 0x4001
        public static const GL_LIGHT2:uint = 0x4002
        public static const GL_LIGHT3:uint = 0x4003
        public static const GL_LIGHT4:uint = 0x4004
        public static const GL_LIGHT5:uint = 0x4005
        public static const GL_LIGHT6:uint = 0x4006
        public static const GL_LIGHT7:uint = 0x4007
        
        /* LightParameter */
        public static const GL_AMBIENT               :uint =  0x1200
        public static const GL_DIFFUSE               :uint =  0x1201
        public static const GL_SPECULAR              :uint =  0x1202
        public static const GL_POSITION              :uint =  0x1203
        public static const GL_SPOT_DIRECTION        :uint =  0x1204
        public static const GL_SPOT_EXPONENT         :uint =  0x1205
        public static const GL_SPOT_CUTOFF           :uint =  0x1206
        public static const GL_CONSTANT_ATTENUATION  :uint =  0x1207
        public static const GL_LINEAR_ATTENUATION    :uint =  0x1208
        public static const GL_QUADRATIC_ATTENUATION :uint =  0x1209
            
        /* MaterialParameter */
        public static const GL_EMISSION                :uint = 0x1600
        public static const GL_SHININESS               :uint = 0x1601
        public static const GL_AMBIENT_AND_DIFFUSE     :uint = 0x1602
        public static const GL_COLOR_INDEXES           :uint = 0x1603
            
        /* Polygon Modes */
        public static const GL_POINT                   :uint = 0x1B00
        public static const GL_LINE                    :uint = 0x1B01
        public static const GL_PFILL                   :uint = 0x1B02
        
        /* Shading model */
        public static const GL_FLAT                     :uint = 0x1D00
        public static const GL_SMOOTH                   :uint = 0x1D01 
            
        /* separate_specular_color */
        public static const GL_LIGHT_MODEL_COLOR_CONTROL :uint = 0x81F8
        public static const GL_SINGLE_COLOR              :uint = 0x81F9
        public static const GL_SEPARATE_SPECULAR_COLOR   :uint = 0x81FA

        /* Texture Env Modes */
        public static const GL_MODULATE:uint = 0x2100
        public static const GL_NEAREST:uint = 0x2600
        public static const GL_LINEAR:uint = 0x2601
        public static const GL_NEAREST_MIPMAP_LINEAR:uint = 0x2702
        public static const GL_TEXTURE_ENV_MODE:uint = 0x2200
        
        /* Make sure to initialize to default values here. */
        private var contextMaterial:Material = new Material(true)
            
        private function setVector(vec:Vector.<Number>, x:Number, y:Number, z:Number, w:Number):void
        {
            vec[0] = x
            vec[1] = y
            vec[2] = z
            vec[3] = w
        }
        
        private function copyVector(dest:Vector.<Number>, src:Vector.<Number>):void
        {
            dest[0] = src[0]
            dest[1] = src[1]
            dest[2] = src[2]
            dest[3] = src[3]
        }
        
        public function glMaterial(face:uint, pname:uint, r:Number, g:Number, b:Number, a:Number):void
        {
            // if pname == GL_SPECULAR, then "r" is shininess.
            // FIXME (klin): Ignore face for now. Always GL_FRONT_AND_BACK
            var material:Material

            if (activeCommandList)
            {
                var activeState:ContextState = activeCommandList.ensureActiveState()
                material = activeCommandList.activeState.material
            }
            else
            {
                material = contextMaterial
            }
            
            
            switch (pname)
            {
                case GL_AMBIENT:
                    if (!material.ambient)
                        material.ambient = new <Number>[r, g, b, a]
                    else
                        setVector(material.ambient, r, g, b, a)
                    break
                case GL_DIFFUSE:
                    if (!material.diffuse)
                        material.diffuse = new <Number>[r, g, b, a]
                    else
                        setVector(material.diffuse, r, g, b, a)
                    break
                case GL_AMBIENT_AND_DIFFUSE:
                    if (!material.ambient)
                        material.ambient = new <Number>[r, g, b, a]
                    else
                        setVector(material.ambient, r, g, b, a)
                    
                    if (!material.diffuse)
                        material.diffuse = new <Number>[r, g, b, a]
                    else
                        setVector(material.diffuse, r, g, b, a)
                    break
                case GL_SPECULAR:
                    if (!material.specular)
                        material.specular = new <Number>[r, g, b, a]
                    else
                        setVector(material.specular, r, g, b, a)
                    break
                case GL_SHININESS:
                    material.shininess = r
                    break
                case GL_EMISSION:
                    if (!material.emission)
                        material.emission = new <Number>[r, g, b, a]
                    else
                        setVector(material.emission, r, g, b, a)
                    break
                default:
                    if (log) log.send("[NOTE] Unsupported glMaterial call with 0x" + pname.toString(16))
            }
        }
        
        
        public function glLightModeli(pname:uint, param:int):void
        {
            switch (pname)
            {
                case GL_LIGHT_MODEL_COLOR_CONTROL:
                        contextSeparateSpecular = (param == GL_SEPARATE_SPECULAR_COLOR)
                        if (contextSeparateSpecular)
                            setGLState(ENABLE_SEPSPEC_OFFSET)
                        else
                            clearGLState(ENABLE_SEPSPEC_OFFSET)
                   break
                
                // unsupported for now
                case GL_LIGHT_MODEL_TWO_SIDE: 
                case GL_LIGHT_MODEL_AMBIENT:
                case GL_LIGHT_MODEL_LOCAL_VIEWER:
                default:
                    break
            }
            
            if (log) log.send("glLightModeli() not yet implemented")
        }
        
        private var lights:Vector.<Light> = new Vector.<Light>(8)
        private var lightsEnabled:Vector.<Boolean> = new Vector.<Boolean>(8)
        
        public function glLight(light:uint, pname:uint, r:Number, g:Number, b:Number, a:Number):void
        {
            var lightIndex:int = light - GL_LIGHT0
            if (lightIndex < 0 || lightIndex > 7)
            {
                if (log) log.send("glLight(): light index " + lightIndex + " out of bounds")
                return
            }
            
            var l:Light = lights[lightIndex]
            if (!l)
                l = lights[lightIndex] = new Light(true, lightIndex == 0)
            
            switch (pname)
            {
                case GL_AMBIENT:
                    l.ambient[0] = r
                    l.ambient[1] = g
                    l.ambient[2] = b
                    l.ambient[3] = a
                    break
                case GL_DIFFUSE:
                    l.diffuse[0] = r
                    l.diffuse[1] = g
                    l.diffuse[2] = b
                    l.diffuse[3] = a
                    break
                case GL_SPECULAR:
                    l.specular[0] = r
                    l.specular[1] = g
                    l.specular[2] = b
                    l.specular[3] = a
                    break
                case GL_POSITION:
                    // transform position to eye-space before storing.
                    var m:Matrix3D = modelViewStack[modelViewStack.length - 1].clone()
                    var result:Vector3D = m.transformVector(new Vector3D(r, g, b, a))
                    l.position[0] = result.x
                    l.position[1] = result.y
                    l.position[2] = result.z
                    l.position[3] = result.w
                    break
                default:
                    break
            }
        }
            
        public static const GL_MAX_TEXTURE_SIZE:uint =          0x0D33
        public static const GL_VIEWPORT:uint =                  0x0BA2

        public function glGetIntegerv(pname:uint, buf:ByteArray, offset:uint):void
        {
            if (log) log.send("glGetIntegerv")
            switch (pname)
            {
                case GL_MAX_TEXTURE_SIZE:
                    buf.position = offset
                    buf.writeInt(4096)
                break
                case GL_VIEWPORT:
                    buf.position = offset+0; buf.writeInt(0); // x
                    buf.position = offset+4; buf.writeInt(0); // y
                    buf.position = offset+8; buf.writeInt(contextWidth); // width
                    buf.position = offset+12; buf.writeInt(contextHeight); // height
                break

                default:
                    if (log) log.send("[NOTE] Unsupported glGetIntegerv call with 0x" + pname.toString(16))
            }
        }

        public function glGetFloatv(pname:uint, buf:ByteArray, offset:uint):void
        {
            if (log) log.send("glGetFloatv")
            switch (pname)
            {
                case GL_MODELVIEW_MATRIX:
                    var v:Vector.<Number> = new Vector.<Number>(16)
                    modelViewStack[modelViewStack.length - 1].copyRawDataTo(v)
                    buf.position = offset
                    for (var i:int; i < 16; i++)
                        buf.writeFloat(v[i])
                    break
                default:
                    if (log) log.send("[NOTE] Unsupported glGetFloatv call with 0x" + pname.toString(16))
            }
        }

        /* ClipPlaneName */
        public static const GL_CLIP_PLANE0:uint = 0x3000
        public static const GL_CLIP_PLANE1:uint = 0x3001
        public static const GL_CLIP_PLANE2:uint = 0x3002
        public static const GL_CLIP_PLANE3:uint = 0x3003
        public static const GL_CLIP_PLANE4:uint = 0x3004
        public static const GL_CLIP_PLANE5:uint = 0x3005
        
        private var clipPlanes:Vector.<Number> = new Vector.<Number>(6 * 4)    // space for 6 clip planes
        private var clipPlaneEnabled:Vector.<Boolean> = new Vector.<Boolean>(8) // defaults to false

        
        public function glClipPlane(plane:uint, a:Number, b:Number, c:Number, d:Number):void
        {
            if (log) log.send("[NOTE] glClipPlane called for plane 0x" + plane.toString(16) + ", with args " + a + ", " + b + ", " + c + ", " + d)
            var index:int = plane - GL_CLIP_PLANE0
            
            // Convert coordinates to eye space (modelView) before storing
            var m:Matrix3D = modelViewStack[modelViewStack.length - 1].clone()
            m.invert()
            m.transpose()
            var result:Vector3D = m.transformVector(new Vector3D(a, b, c, d))
            
            clipPlanes[ index * 4 + 0 ] = result.x
            clipPlanes[ index * 4 + 1 ] = result.y
            clipPlanes[ index * 4 + 2 ] = result.z
            clipPlanes[ index * 4 + 3 ] = a * m.rawData[3] + b * m.rawData[7] + c * m.rawData[11] + d * m.rawData[15] //result.w
        }

        private const consts:Vector.<Number> = new <Number>[0.0, 0.5, 1.0, 2.0]
        private const zeroes:Vector.<Number> = new <Number>[0.0, 0.0, 0.0, 0.0]
        private var shininessVec:Vector.<Number> = new <Number>[0.0, 0.0, 0.0, 0.0]
        private var globalAmbient:Vector.<Number> = new <Number>[0.2, 0.2, 0.2, 1]
        
        private var polygonOffsetValue:Number = -0.0005

        private function executeCommandList(cl:CommandList):void
        {
            // FIXME (egeorgire): do this on-deamnd?
            // Pre-calculate matrix
            var m:Matrix3D = modelViewStack[modelViewStack.length - 1].clone()
            var p:Matrix3D = projectionStack[projectionStack.length - 1].clone()
            var t:Matrix3D = textureStack[textureStack.length - 1].clone()
            //m.append(p)
            
            
            p.prepend(m)
            var invM:Matrix3D = m.clone()
            invM.invert()
            var modelToClipSpace:Matrix3D = p

            if (isGLState(ENABLE_POLYGON_OFFSET))
            {
                // Adjust the projection matrix to give us z offset
                if (log)
                    log.send("Applying polygon offset")
                
                modelToClipSpace = p.clone()
                modelToClipSpace.appendTranslation(0, 0, polygonOffsetValue)
            }
            
            
            // Current active textures ??
            var ti:TextureInstance
            var i:int
            for (i = 0; i < 1; i++ )
            {
                ti = textureSamplers[i]
                if (ti && contextEnableTextures) {
                    context.setTextureAt(i, ti.boundType == GL_TEXTURE_2D ? ti.texture : ti.cubeTexture)
                    if(log) log.send("setTexture " + i + " -> " + ti.texID)
                }
                else {
                    context.setTextureAt(i, null)
                    if(log) log.send("setTexture " + i + " -> 0")
                }
            }
            
            var textureStatInvalid:Boolean = false;
            const count:int = cl.commands.length
            var command:Object
            for (var k:int = 0; k < count; k++)
            {
                command = cl.commands[k]
                var stateChange:ContextState = command as ContextState
                if (stateChange)
                {
                
                    // We execute state changes before stream changes, so
                    // we must have a state change
    
                    // Execute state changes
                    if (contextEnableTextures && stateChange.textureSamplers)
                    {
                        for (i = 0; i < 1; i++ )
                        {
                            var texID:int = stateChange.textureSamplers[i]
                            if (texID != -1)
                            {
                                if (log) log.send("Mapping texture " + texID + " to sampler " + i)
                                ti = (texID != 0) ? textures[texID] : null
                                textureSamplers[i] = ti
                                activeTexture = ti // Executing the glBind, so that after running through the list we have the side-effect correctly
                                textureStatInvalid = true
                                if (ti)
                                    context.setTextureAt(i, ti.boundType == GL_TEXTURE_2D ? ti.texture : ti.cubeTexture)
                                else
                                    context.setTextureAt(i, null)
                                if(log) log.send("setTexture " + i + " -> " + (ti ? ti.texID : 0))
                            }
                        }
                    }
                    
                    var stateMaterial:Material = stateChange.material
                    if (stateMaterial)
                    {
                        if (stateMaterial.ambient)
                            copyVector(contextMaterial.ambient, stateMaterial.ambient)
                        if (stateMaterial.diffuse)
                            copyVector(contextMaterial.diffuse, stateMaterial.diffuse)
                        if (stateMaterial.specular)
                            copyVector(contextMaterial.specular, stateMaterial.specular)
                        if (!isNaN(stateMaterial.shininess))
                            contextMaterial.shininess = stateMaterial.shininess
                        if (stateMaterial.emission)
                            copyVector(contextMaterial.emission, stateMaterial.emission)
                    }
                }

                var stream:VertexStream = command as VertexStream
                if (stream)
                {
                    
                    // Make sure we have the right program, and see if we need to updated it if some state change requires it
                    ensureProgramUpToDate(stream)
                    
                    // If the program has no textures, then disable them all:
                    if (!stream.program.hasTexture)
                    {
                        for (i = 0; i < 8; i++ )
                        {
                            context.setTextureAt(i, null)
                            if(log) log.send("setTexture " + i + " -> 0")
                        }
                    }
                    
                    context.setProgram(stream.program.program)

                    // FIXME (egeorgie): do we need to do this after setting every program, or just once after we calculate the matrix?
                    if (stream.polygonOffset)
                    {
                        // Adjust the projection matrix to give us z offset
                        if (log)
                            log.send("Applying polygon offset, recorded in the list")
                        modelToClipSpace = p.clone()
                        modelToClipSpace.appendTranslation(0, 0, polygonOffsetValue)
                    }
                    context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, modelToClipSpace, true)
                    if (stream.polygonOffset)
                    {
                        // Restore
                        modelToClipSpace = p
                    }
                    context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 4, m, true)
                    context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 8, invM, true)
                    context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 12, t, true)
                    context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 16, consts)
                    context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 17, contextColor)

                    // Upload the clip planes
                    context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 18, clipPlanes, 6)

                    // Zero-out the ones that are not enabled
                    for (i = 0; i < 6; i++)
                    {
                        if (!clipPlaneEnabled[i])
                            context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 18 + i, zeroes, 1)
                    }
                    
                    // Calculate origin of eye-space
                    context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 24, new <Number>[0, 0, 0, 1], 1)
                    
                    // Upload material components
                    context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 25, contextMaterial.ambient, 1)
                    context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 26, contextMaterial.diffuse, 1)
                    context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 27, contextMaterial.specular, 1)
                    shininessVec[0] = contextMaterial.shininess
                    context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 28, shininessVec, 1)
                    context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 29, contextMaterial.emission, 1)
                    
                    // Upload lights
                    // FIXME (klin): will be per light...for now, fake a light and assume local viewer.
                    // default global light:
                    context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 30, globalAmbient, 1)
                    
                    // light constants
                    for (i = 0; i < 8; i++)
                    {
                        var index:int = 31 + i*4
                        if (lightsEnabled[i])
                        {
                            var l:Light = lights[i]
                            context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, index, l.position, 1)
                            context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, index+1, l.ambient, 1)
                            context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, index+2, l.diffuse, 1)
                            context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, index+3, l.specular, 1)
                        }
                        else
                        {
                            context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, index, zeroes, 1)
                            context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, index+1, zeroes, 1)
                            context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, index+2, zeroes, 1)
                            context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, index+3, zeroes, 1)
                        }

                    }



                    // Map the Vertex buffer
                    
                    // position
                    context.setVertexBufferAt(0, stream.vertexBuffer, 0 /*bufferOffset*/, Context3DVertexBufferFormat.FLOAT_3)

                    // color
                    if (0 != (stream.program.vertexStreamUsageFlags & VertexBufferBuilder.HAS_COLOR))
                        context.setVertexBufferAt(1, stream.vertexBuffer, 3 /*bufferOffset*/, Context3DVertexBufferFormat.FLOAT_4)
                    else
                        context.setVertexBufferAt(1, null) 

                    // normal
                    if (0 != (stream.program.vertexStreamUsageFlags & VertexBufferBuilder.HAS_NORMAL))
                        context.setVertexBufferAt(2, stream.vertexBuffer, 7 /*bufferOffset*/, Context3DVertexBufferFormat.FLOAT_3)
                    else
                        context.setVertexBufferAt(2, null) 

                    // texture coords
                    if (0 != (stream.program.vertexStreamUsageFlags & VertexBufferBuilder.HAS_TEXTURE2D))
                        context.setVertexBufferAt(3, stream.vertexBuffer, 10 /*bufferOffset*/, Context3DVertexBufferFormat.FLOAT_2)
                    else
                        context.setVertexBufferAt(3, null) 

                    context.drawTriangles(stream.indexBuffer)
                    
                    // If we're executing on compilation, this may be an immediate command stream, so update the pool
                    if (cl.executeOnCompile)
                        immediateVertexBuffers.markInUse(stream.vertexBuffer)
                }
            }
        }

        //    extern GLuint glGenLists (GLsizei range)
        public function glGenLists(count:uint):uint
        {
            if (log) log.send("glGenLists " + count)
            if (!commandLists)
                commandLists = new Vector.<CommandList>()
            
            var oldLength:int = commandLists.length
            commandLists.length = oldLength + count
            return oldLength
        }
        
        // ---------------------------------- GL MATRIX STACK ---
        
        private var modelViewStack:Vector.<Matrix3D> = new <Matrix3D>[ new Matrix3D() ]
        private var projectionStack:Vector.<Matrix3D> = new <Matrix3D>[ new Matrix3D() ]
        private var textureStack:Vector.<Matrix3D> = new <Matrix3D>[ new Matrix3D() ]
        private var currentMatrixStack:Vector.<Matrix3D> = modelViewStack
        
        /* MatrixMode */
        public static const GL_MODELVIEW:uint = 0x1700
        public static const GL_PROJECTION:uint = 0x1701
        public static const GL_TEXTURE:uint = 0x1702
        
        // For Debug purposes
        public static const MATRIX_MODE:Array = [
            "GL_MODELVIEW",
            "GL_PROJECTION",
            "GL_TEXTURE",
            ]

        public function glMatrixMode(mode:uint):void
        {
            if (log) log.send("glMatrixMode \nSwitch stack to " + MATRIX_MODE[mode - GL_MODELVIEW])
            
            switch (mode)
            {
                case GL_MODELVIEW: 
                    currentMatrixStack = modelViewStack
                break
                
                case GL_PROJECTION:
                    currentMatrixStack = projectionStack
                break
                
                case GL_TEXTURE:
                    currentMatrixStack = textureStack
                break

                default:
                    if (log) log.send("Unknown Matrix Mode " + mode)
            }
        }
        
        public function glPushMatrix():void
        {
            if (log) log.send("glPushMatrix")
            currentMatrixStack.push(currentMatrixStack[currentMatrixStack.length - 1].clone())
        }
        
        public function glPopMatrix():void
        {
            if (log) log.send("glPopMatrix")
            currentMatrixStack.pop()
            if(currentMatrixStack.length == 0) {
                trace("marix stack underflow!")
                currentMatrixStack.push(new Matrix3D())
            }
        }
        
        public function glLoadIdentity():void
        {
            if (log) log.send("glLoadIdentity")
            currentMatrixStack[currentMatrixStack.length - 1].identity()
        }
        
        public function glOrtho(left:Number, right:Number, bottom:Number, top:Number, zNear:Number, zFar:Number):void
        {
            if (log) log.send("glOrtho: left = " + left + ", right = " + right + ", bottom = " + bottom + ", top = " + top + ", zNear = " + zNear + ", zFar = " + zFar)
            
            var tx:Number = - (right + left) / (right - left)
            var ty:Number = - (top + bottom) / (top - bottom)
            var tz:Number = - (zFar + zNear) / (zFar - zNear)
            
            // in column-major order...
            var m:Matrix3D = new Matrix3D( new <Number>[
                                            2 / (right - left), 0, 0, 0,
                                            0, 2 / (top - bottom), 0, 0,
                                            0, 0, - 2 / ( zFar - zNear), 0,
                                            tx, ty, tz, 1]
                )
            
            // Multiply current matrix by the ortho matrix
            currentMatrixStack[currentMatrixStack.length - 1].prepend(m)
        }
        
        public function glTranslate(x:Number, y:Number, z:Number):void
        {
            if (log) log.send("glTranslate")
            currentMatrixStack[currentMatrixStack.length - 1].prependTranslation(x, y, z)
        }
        
        public function glRotate(degrees:Number, x:Number, y:Number, z:Number):void
        {
            if (log) log.send("glRotate")
            currentMatrixStack[currentMatrixStack.length - 1].prependRotation(degrees, new Vector3D(x, y, z))
        }
        
        public function glScale(x:Number, y:Number, z:Number):void
        {
            if (log) log.send("glScale")
            
            if (x != 0 && y != 0 && z != 0)
            currentMatrixStack[currentMatrixStack.length - 1].prependScale(x, y, z)
        }
        
        public function glMultMatrix(ram:ByteArray, floatArray:Boolean):void
        {
            if (log) log.send("glMultMatrix floatArray: " + floatArray.toString())

            var v:Vector.<Number> = new Vector.<Number>(16)
            for (var i:int; i < 16; i++)
                v[i] = floatArray ? ram.readFloat() : ram.readDouble()
            var m:Matrix3D = new Matrix3D(v)
            currentMatrixStack[currentMatrixStack.length - 1].prepend(m)
        }
        
        public function multMatrix(m:Matrix3D):void
        {
            currentMatrixStack[currentMatrixStack.length - 1].prepend(m)
        }

        public function glLoadMatrix(ram:ByteArray, floatArray:Boolean):void
        {
            if (log) log.send("glLoadMatrix floatArray: " + floatArray.toString())

            var v:Vector.<Number> = new Vector.<Number>(16)
            for (var i:int; i < 16; i++)
                v[i] = floatArray ? ram.readFloat() : ram.readDouble()
            var m:Matrix3D = new Matrix3D(v)
            currentMatrixStack[currentMatrixStack.length - 1] = m
        }
        
        // ------------------------------------------------------
        public function glDepthMask(enable:Boolean):void
        {
            if (log) log.send("glDepthMask(" + enable + "), currently contextEnableDepth = " + contextEnableDepth)
            contextDepthMask = enable
            if (contextEnableDepth)
            {
                context.setDepthTest(contextDepthMask, contextDepthFunction)
            }
        }
        
        /* AlphaFunction */
        /* DepthFunction */
        /* StencilFunction */
        public static const GL_NEVER:uint      = 0x0200
        public static const GL_LESS:uint       = 0x0201
        public static const GL_EQUAL:uint      = 0x0202
        public static const GL_LEQUAL:uint     = 0x0203
        public static const GL_GREATER:uint    = 0x0204
        public static const GL_NOTEQUAL:uint   = 0x0205
        public static const GL_GEQUAL:uint     = 0x0206
        public static const GL_ALWAYS:uint     = 0x0207
        
        public static const COMPARE_MODE:Array = [
            "GL_NEVER",
            "GL_LESS",
            "GL_EQUAL",
            "GL_LEQUAL",
            "GL_GREATER",
            "GL_NOTEQUAL",
            "GL_GEQUAL",
            "GL_ALWAYS",
            ]

        private var contextDepthFunction:String = Context3DCompareMode.LESS
        
        public function glDepthFunc(mode:uint):void
        {
            if (log) log.send("glDepthFunc( " + COMPARE_MODE[mode - GL_NEVER] + " ), currently contextEnableDepth = " + contextEnableDepth)
        
            contextDepthFunction = convertCompareMode(mode)
            if (contextEnableDepth)
                context.setDepthTest(contextDepthMask, contextDepthFunction)
        }

        private function convertCompareMode(mode:uint):String
        {
            switch (mode)
            {
                case GL_NEVER: return Context3DCompareMode.NEVER
                case GL_LESS: return Context3DCompareMode.LESS
                case GL_EQUAL: return Context3DCompareMode.EQUAL
                case GL_LEQUAL: return Context3DCompareMode.LESS_EQUAL
                case GL_GREATER: return Context3DCompareMode.GREATER
                case GL_NOTEQUAL: return Context3DCompareMode.NOT_EQUAL
                case GL_GEQUAL: return Context3DCompareMode.GREATER_EQUAL
                case GL_ALWAYS: return Context3DCompareMode.ALWAYS
            }
            return null
        }
        
        // ------------------------------------------------------
        
        /* TextureCoordName */
        public static const GL_S:uint =         0x2000
        public static const GL_T:uint =         0x2001
        public static const GL_R:uint =         0x2002
        public static const GL_Q:uint =         0x2003

        public static const GL_COORD_NAME:Array = [
            "GL_S",
            "GL_T",
            "GL_R",
            "GL_Q",
        ]

        /* TextureGenParameter */
        public static const GL_TEXTURE_GEN_MODE:uint =  0x2500
        public static const GL_OBJECT_PLANE:uint =      0x2501
        public static const GL_EYE_PLANE:uint =         0x2502

        public static const GL_PARAM_NAME:Array = [
            "GL_TEXTURE_GEN_MODE",
            "GL_OBJECT_PLANE",
            "GL_EYE_PLANE",
        ]

        /* param */
        public static const GL_EYE_LINEAR:uint =        0x2400
        public static const GL_OBJECT_LINEAR:uint =     0x2401
        public static const GL_SPHERE_MAP:uint =        0x2402
        public static const GL_NORMAL_MAP:uint =        0x8511
        public static const GL_REFLECTION_MAP:uint =    0x8512
        
        public static const GL_PARAM:Array = [
            "GL_EYE_LINEAR",
            "GL_OBJECT_LINEAR",
            "GL_SPHERE_MAP",
            "GL_NORMAL_MAP",
            "GL_REFLECTION_MAP",
        ]
        
        
        private function texGenParamToString(param:uint):String
        {
            if (param < GL_NORMAL_MAP)
                return GL_PARAM[param - GL_EYE_LINEAR]
            else
                return GL_PARAM[param - GL_NORMAL_MAP]
        }
        
        
        public static const GL_TEXTURE_GEN_S:uint = 0x0C60
        public static const GL_TEXTURE_GEN_T:uint = 0x0C61
        public static const GL_TEXTURE_GEN_R:uint = 0x0C62
        public static const GL_TEXTURE_GEN_Q:uint = 0x0C63
        
        private var enableTexGenS:Boolean = false
        private var enableTexGenT:Boolean = false
        private var texGenParamS:uint = GL_SPHERE_MAP
        private var texGenParamT:uint = GL_SPHERE_MAP
        
        
        public function glTexGeni(coord:uint, pname:uint, param:uint):void
        {
            if (log) log.send("glTexGeni( " + GL_COORD_NAME[coord - GL_S] + ", " + GL_PARAM_NAME[pname - GL_TEXTURE_GEN_MODE] + ", " + texGenParamToString(param) + ")")
            
            if (GL_T < coord)
            {
                if (log) log.send("Unsupported " + GL_COORD_NAME[coord - GL_S])
                return
            }
            
            if (pname != GL_TEXTURE_GEN_MODE)
            {
                if (log) log.send("Unsupported " + GL_PARAM_NAME[pname - GL_TEXTURE_GEN_MODE])
                return
            }
            
            switch (coord)
            {
                case GL_S:
                    texGenParamS = param
                break
                
                case GL_T:
                    texGenParamT = param
                break
            }
        }
        
        /* BeginMode */
        public static const GL_POINTS:uint           = 0x0000
        public static const GL_LINES:uint            = 0x0001
        public static const GL_LINE_LOOP:uint        = 0x0002
        public static const GL_LINE_STRIP:uint       = 0x0003
        public static const GL_TRIANGLES:uint        = 0x0004
        public static const GL_TRIANGLE_STRIP:uint   = 0x0005
        public static const GL_TRIANGLE_FAN:uint     = 0x0006
        public static const GL_QUADS:uint            = 0x0007
        public static const GL_QUAD_STRIP:uint       = 0x0008
        public static const GL_POLYGON:uint          = 0x0009

        // For Debug purposes
        public static const BEGIN_MODE:Array = [
            "GL_POINTS",
            "GL_LINES",
            "GL_LINE_LOOP",
            "GL_LINE_STRIP",
            "GL_TRIANGLES",
            "GL_TRIANGLE_STRIP",
            "GL_TRIANGLE_FAN",
            "GL_QUADS",
            "GL_QUAD_STRIP",
            "GL_POLYGON",
        ]

        public function glBegin(mode:uint):void
        {
            if (!vbb)
            {
                vbb = new VertexBufferBuilder()
            }
            vbb.reset()
            vbb.mode = mode
            
            if (log) log.send("glBegin(), Mode is " + BEGIN_MODE[mode])
        }

        public function renderAllLists():void
        {
            for (var i:int = 0; i < commandLists.length; i++)
            {
                executeCommandList(commandLists[i])
            }
        }
        
        private var sharedIndexBuffers:Dictionary = new Dictionary()
        
        private function setupIndexBuffer(stream:VertexStream, mode:uint, count:int):void
        {
            var key:uint = ((mode << 20) | count)
            var indexBuffer:IndexBuffer3D = sharedIndexBuffers[key]

            if (!indexBuffer)
            {
                var indexData:Vector.<uint> = new Vector.<uint>()
                generateDLIndexData(mode, count, indexData)
                indexBuffer = context.createIndexBuffer(indexData.length)
                indexBuffer.uploadFromVector(indexData, 0, indexData.length)
                
                // Cache
                sharedIndexBuffers[key] = indexBuffer
            }
            stream.indexBuffer = indexBuffer
        }
        
        private function generateDLIndexData(mode:uint, count:int, indexData:Vector.<uint>):void
        {
            var i:int
            var p0:int
            var p1:int
            var p2:int
            var p3:int
            
            switch (mode)
            {
                case GL_QUADS:
                    // Assert count == n * 4, n >= 1
                    // for each group of 4 vertices 0, 1, 2, 3 draw two triangles 0, 1, 2 and 0, 2, 3
                    
                    for (i = 0; i < count; i += 4)
                    {
                        indexData.push(i)
                        indexData.push(i + 1)
                        indexData.push(i + 2)

                        indexData.push(i)
                        indexData.push(i + 2)
                        indexData.push(i + 3)
                    }
                    
                break
                
                case GL_QUAD_STRIP:
                    // Assert count == n * 2, n >= 2
                    // Draws a connected group of quadrilaterals. One quadrilateral is defined for each pair of vertices presented after the first pair.
                    // Vertices 2n - 2, 2n - 1, 2n + 1, 2n  define a quadrilateral.
                    
                    for (i = 0; i < count - 2; i += 2)
                    {
                        // The four corners of the quadrilateral are

                        p0 = i
                        p1 = i + 1
                        p2 = i + 2
                        p3 = i + 3
                        
                        // Draw as two triangles 0, 1, 2 and 2, 1, 3
                        indexData.push(p0)
                        indexData.push(p1)
                        indexData.push(p2)
                        
                        indexData.push(p2)
                        indexData.push(p1)
                        indexData.push(p3)
                    }
                    
                break

                case GL_TRIANGLES:
                    for (i = 0; i <count; i++)
                    {
                        indexData.push(i)
                    }
                break

               case GL_TRIANGLE_STRIP:
                    for (i = 0; i < count - 2; i++)
                    {
                        p0 = i
                        p1 = i + 1
                        p2 = i + 2

                        indexData.push(p0)
                        if(i % 2 == 0) {
                            indexData.push(p1)
                            indexData.push(p2)
                        } else {
                            indexData.push(p2)
                            indexData.push(p1)
                        }
                    }
                break

                case GL_POLYGON:
                case GL_TRIANGLE_FAN:
                    for (i = 0; i < count-2; i++)
                    {
                        p0 = i + 1
                        p1 = i + 2
                        
                        indexData.push(0)
                        indexData.push(p0)
                        indexData.push(p1)
                    }
                break

                default:
                    if (log) log.send("Not yet implemented mode for glBegin " + BEGIN_MODE[mode])
                    for (i = 0; i <count; i++)
                    {
                        indexData.push(i)
                    }
            }
        }
        
        private var reusableCommandList:CommandList = new CommandList()
        private var reusableVertexBuffers:Dictionary = new Dictionary()
        
        private var immediateVertexBuffers:VertexBufferPool = new VertexBufferPool()
        
        public function glEndVertexData(count:uint, mode:uint, data:ByteArray, dataPtr:uint, dataHash:uint, flags:uint):void
        {
            // FIXME: build an actual VertexBuffer3D
            //var buffer:DataBuffer = acquireBufferFromPool(numElements, data32PerVertext, target)
            if (log) log.send("glEnd()")

            // FIXME (egeorgie): refactor into the VertexBufferbuilder
            const data32PerVertex:int = 12 // x, y, z,  r, g, b, a,  nx, ny, nz, tx, ty 
            
            // Number of Vertexes
            if (count == 0)
            {
                if (log) log.send("0 vertices, no-op")
                return
            }
            
            var b:VertexBuffer3D
            if (activeCommandList)
            {
                b = this.context.createVertexBuffer(count, data32PerVertex)
                b.uploadFromByteArray(data, dataPtr, 0, count)
            }
            else 
            {
                b = immediateVertexBuffers.acquire(dataHash, count, data, dataPtr)
                if (!b)
                {
                    b = immediateVertexBuffers.allocateOrReuse(dataHash, count, data, dataPtr, context)
                }
            }       
            
            var cl:CommandList = activeCommandList
            
            // If we don't have a list, create a temporary one and execute it on glEndList()
            if (!cl)
            {
                cl = reusableCommandList
                cl.executeOnCompile = true
                cl.commands.length = 0
                cl.activeState = null
            }
            
            var stream:VertexStream = new VertexStream()
            stream.vertexBuffer = b
            //stream.indexBuffer = indexBuffer
            stream.vertexFlags = flags
            stream.polygonOffset = isGLState(ENABLE_POLYGON_OFFSET)
            
            setupIndexBuffer(stream, mode, count)
            
            // Remember whether we need to generate texture coordiantes on the fly,
            // we'll use that value later on to pick the right shader when we render the list
            
            if (enableTexGenS)
            {
                if (texGenParamS == GL_SPHERE_MAP)
                    stream.vertexFlags |= VertexBufferBuilder.TEX_GEN_S_SPHERE
                else
                    if (log) log.send("[Warning] Unsupported glTexGen mode for GL_S: 0x" + texGenParamS.toString(16))
            }
            
            if (enableTexGenT)
            {
                if (texGenParamT == GL_SPHERE_MAP)
                    stream.vertexFlags |= VertexBufferBuilder.TEX_GEN_T_SPHERE
                else
                    if (log) log.send("[Warning] Unsupported glTexGen mode for GL_S: 0x" + texGenParamT.toString(16))
            }
            
            //stream.program = getFixedFunctionPipelineProgram(vbb.flags)
            
            // Make sure that if we have any active state changes, we push them in front of the stream commands
            if (cl.activeState)
            {
                cl.commands.push(cl.activeState)
                cl.activeState = null
            }
            
            cl.commands.push(stream)
            
            if (!activeCommandList)
            {
                if (log) log.send("Rendering Immediate Vertex Stream ")
                executeCommandList(cl)
            }
        }
        
        public function glEnd():void
        {
            glEndVertexData(vbb.count, vbb.mode, vbb.data, 0, VertexBufferPool.calcHash(vbb.count, vbb.data, 0), vbb.flags)
        }
        
        private var glStateFlags:uint = 0
        
        // bit 0 = whether textures are enabled
        private const ENABLE_TEXTURE_OFFSET:uint = 0
        // bits 1-6 = whether clip planes 0-5 are enabled
        private const ENABLE_CLIPPLANE_OFFSET:uint = 1
        // bit 7 = whether color material is enabled
        private const ENABLE_COLOR_MATERIAL_OFFSET:uint = 7
        // bit 8 = whether lighting is enabled
        private const ENABLE_LIGHTING_OFFSET:uint = 8
        // bit 9-16 = whether lights 0-7 are enabled
        private const ENABLE_LIGHT_OFFSET:uint = 9
        // bit 17 = whether specular is separate
        private const ENABLE_SEPSPEC_OFFSET:uint = 17
        // bit 18 = whether polygon offset is enabled
        private const ENABLE_POLYGON_OFFSET:uint = 18
        
        private function setGLState(bit:uint):void
        {
            glStateFlags |= (1 << bit)
        }
        
        private function clearGLState(bit:uint):void
        {
            glStateFlags &= ~(1 << bit)
        }
        
        private function isGLState(bit:uint):Boolean
        {
            return 0 != (glStateFlags & (1 << bit))
        }

        private function getFixedFunctionPipelineKey(flags:uint):String
        {
            var key:String = flags.toString() + glStateFlags.toString();

            if (0 != (flags & VertexBufferBuilder.HAS_TEXTURE2D))
            {
                for(var i:int=0; i<8; i++)
                {
                    key = key.concat("ti", i,",")
                     var ti:TextureInstance = textureSamplers[i]
                     if (ti) {
                         var textureParams:TextureParams = ti.params
                        key = key.concat((textureParams ? textureParams.GL_TEXTURE_WRAP_S : 0), ",",
                                        (textureParams ? textureParams.GL_TEXTURE_WRAP_T : 0), ",",
                                        (textureParams ? textureParams.GL_TEXTURE_MIN_FILTER : 0), ",",
                                        (ti.mipLevels > 1 ? 1 : 0))
                    }
                }
                
            }
            return key
        }
        
        private var fixed_function_programs:Dictionary = new Dictionary()
        
        private function ensureProgramUpToDate(stream:VertexStream):void
        {
            var flags:uint = stream.vertexFlags
            var key:String = getFixedFunctionPipelineKey(flags)
            if (log) log.send("program key is:" + key)
            
            if (!stream.program || stream.program.key != key)
                stream.program = getFixedFunctionPipelineProgram(key, flags)
        }
        
        private function getFixedFunctionPipelineProgram(key:String, flags:uint):FixedFunctionProgramInstance
        {
            var p:FixedFunctionProgramInstance = fixed_function_programs[ key ]
            
            if (!p)
            {
                p = new FixedFunctionProgramInstance()
                p.key = key
                fixed_function_programs[key] = p
                
                p.program = context.createProgram()
                p.hasTexture = contextEnableTextures &&
                               ((0 != (flags & VertexBufferBuilder.HAS_TEXTURE2D)) ||
                                (0 != (flags & VertexBufferBuilder.TEX_GEN_S_SPHERE) && 0 != (flags & VertexBufferBuilder.TEX_GEN_T_SPHERE)))

                var textureParams:TextureParams = null
                var ti:TextureInstance
                if (p.hasTexture)
                {
                    // FIXME (egeorgie): Assume sampler 0
                    ti = textureSamplers[0]
                    if (ti)
                        textureParams = ti.params
                }

                // For all Vertex shaders:
                //
                // va0 - position
                // va1 - color
                // va2 - normal
                // va3 - texture coords
                //
                // vc0,1,2,3 - modelViewProjection
                // vc4,5,6,7 - modelView
                // vc8,9,10,11 - inverse modelView
                // vc12, 13, 14, 15 - texture matrix
                // vc16 - (0, 0.5, 1.0, 2.0)
                // vc17 - current color state (to be used when vertex color is not specified)
                // vc18 - clipPlane0 
                // vc19 - clipPlane1 
                // vc20 - clipPlane2 
                // vc21 - clipPlane3 
                // vc22 - clipPlane4 
                // vc23 - clipPlane5
                //
                // v6, v7 - reserved for clipping
                
                // For all Fragment shaders 
                // v4 - reserved for specular color
                // v5 - reserved for incoming color (either per-vertex color or the current color state) 
                // v6 - dot(clipPlane0, pos), dot(clipPlane1, pos), dot(clipPlane2, pos), dot(clipPlane3, pos) 
                // v7 - dot(clipPlane4, pos), dot(clipPlane5, pos) 
                //

                const _vertexShader_Color_Flags:uint = 0//VertexBufferBuilder.HAS_COLOR
                const _vertexShader_Color:String = [
                    "m44 op, va0, vc0",     // multiply vertex by modelViewProjection
                ].join("\n")

                const _debugShader_Color:String = [
                    "m44 op, va0, vc0",     // multiply vertex by modelViewProjection
                    "mov v0, va1",          // copy the vertex color to be interpolated per fragment
                    "mov v0, vc16", // solid blue for debugging
                ].join("\n")

                const _fragmentShader_Color:String = [
                    "mov ft0, v5",
                    "add ft0.xyz, ft0.xyz, v4.xyz",                 // add specular color
                    "mov oc, ft0",           // output the interpolated color
                ].join("\n")
                

                const _vertexShader_Texture_Flags:uint = VertexBufferBuilder.HAS_TEXTURE2D
                const _vertexShader_Texture:String = [
                    "m44 op, va0, vc0",     // multiply vertex by modelViewProjection
                    "m44 v1, va3, vc12",    // multiply texture coords by texture matrix
                ].join("\n")

                const _fragmentShader_Texture:String = [
                    "tex ft0, v1, fs0 <2d, wrapMode, minFilter> ",     // sample the texture
                    "mul ft0, ft0, v5",                             // modulate with the interpolated color (hardcoding GL_TEXTURE_ENV_MODE to GL_MODULATE)
                    "add ft0.xyz, ft0.xyz, v4.xyz",                 // add specular color
                    "mov oc, ft0",                                  // output interpolated color.                             
                ].join("\n")

//                for(i=0 i<total i++)
//                {
//                    myEyeVertex = MatrixTimesVector(ModelviewMatrix, myVertex[i])
//                    myEyeVertex = Normalize(myEyeVertex)
//                    myEyeNormal = VectorTimesMatrix(myNormal[i], InverseModelviewMatrix)
//                    reflectionVector = myEyeVertex - myEyeNormal * 2.0 * dot3D(myEyeVertex, myEyeNormal)
//                    reflectionVector.z += 1.0
//                    m = 1.0 / (2.0 * sqrt(dot3D(reflectionVector, reflectionVector)))
//                    //I am emphasizing that we write to s and t. Used to sample a 2D texture.
//                    myTexCoord[i].s = reflectionVector.x * m + 0.5
//                    myTexCoord[i].t = reflectionVector.y * m + 0.5
//                }
                
                
                // For all Vertex shaders:
                //
                // va0 - position
                // va1 - color
                // va2 - normal
                // va3 - texture coords
                //
                // vc0,1,2,3 - modelViewProjection
                // vc4,5,6,7 - modelView
                // vc8,9,10,11 - inverse modelView
                // vc12, 13, 14, 15 - texture matrix
                // vc16 - (0, 0.5, 1.0, 2.0)
                //
                
                const _vertexShader_GenTexSphereST_Flags:uint = VertexBufferBuilder.HAS_NORMAL
                const _vertexShader_GenTexSphereST:String = [
                    "m44 op, va0, vc0",     // multiply vertex by modelViewProjection
                    
                    "m44 vt0, va0, vc4",        // eyeVertex = vt0 = pos * modelView 
                    "nrm vt0.xyz, vt0",         // normalize vt0
                    "m44 vt1, va2, vc8",        // eyeNormal = vt1 = normal * inverse modelView
                    "nrm vt1.xyz, vt1",
                    
                    // vt2 = vt0 - vt1 * 2 * dot(vt0, vt1):
                    "dp3 vt4.x, vt0, vt1",          // vt4.x = dot(vt0, vt1)     
                    "mul vt4.x, vt4.x, vc16.w",     // vt4.x *= 2.0
                    "mul vt4, vt1, vt4.x",   // vt4 = vt1 * 2.0 * dot (vt0, vt1)
                    "sub vt2, vt0, vt4",    // 
                    "add vt2.z, vt2.z, vc16.z", // vt2.z += 1.0
                    // vt2 is the reflectionVector now

                    // m = vt4.x = 1 / (2.0 * sqrt(dot3D(reflectionVector, reflectionVector))
                    "dp3 vt4.x, vt2, vt2",
                    "sqt vt4.x, vt4.x",
                    "mul vt4.x, vt4.x, vc16.w",
                    "rcp vt4.x, vt4.x",
                    // vt4.x is m now 

                    // myTexCoord[i].s = reflectionVector.x * m + 0.5
                    // myTexCoord[i].t = reflectionVector.y * m + 0.5
                    "mul vt3.x, vt2.x, vt4.x",
                    "add vt3.x, vt3.x, vc16.y",  // += 0.5 
                    "mul vt3.y, vt2.y, vt4.x",
                    "add vt3.y, vt3.y, vc16.y",  // += 0.5

                    // zero-out the rest z & w
                    "mov vt3.z, vc16.x",
                    "mov vt3.w, vc16.x",

                    // copy the texture coordiantes to be interpolated per fragment
                    "mov v1, vt3",          
                   // "mov v1, va2",          // copy the vertex color to be interpolated per fragment
                ].join("\n")
                
                const _fragmentShader_GenTexSphereST:String = [
                    "tex ft0, v1, fs0 <2d, wrapMode, minFilter> ",     // sample the texture 
                    "mul ft0, ft0, v5",                             // modulate with the interpolated color (hardcoding GL_TEXTURE_ENV_MODE to GL_MODULATE)
                    "add ft0.xyz, ft0.xyz, v4.xyz",                 // add specular color
                    "mov oc, ft0",
                ].join("\n")   

                var vertexShader:String
                var fragmentShader:String

                if (p.hasTexture)
                {
                    if (0 != (flags & VertexBufferBuilder.TEX_GEN_S_SPHERE) &&
                        0 != (flags & VertexBufferBuilder.TEX_GEN_T_SPHERE))
                    {
                        if (log) log.send("using reflection shaders...")
                        vertexShader = _vertexShader_GenTexSphereST
                        p.vertexStreamUsageFlags = _vertexShader_GenTexSphereST_Flags
                        fragmentShader = _fragmentShader_GenTexSphereST
                    }
                    else if (0 != (flags & VertexBufferBuilder.HAS_TEXTURE2D))
                    {
                        if (log) log.send("using texture shaders...")
                        vertexShader = _vertexShader_Texture
                        p.vertexStreamUsageFlags = _vertexShader_Texture_Flags
    
                        if (textureParams.GL_TEXTURE_WRAP_S != textureParams.GL_TEXTURE_WRAP_T)
                        {
                            if (log) log.send("[Warning] Unsupported different texture addressing modes for S and T: 0x" + 
                                textureParams.GL_TEXTURE_WRAP_S.toString(16) + ", 0x" +
                                textureParams.GL_TEXTURE_WRAP_T.toString(16))
                        }
    
                        if (textureParams.GL_TEXTURE_WRAP_S != GL_REPEAT && textureParams.GL_TEXTURE_WRAP_S != GL_CLAMP)
                        {
                            if (log) log.send("[Warning] Unsupported texture wrap mode: 0x" + textureParams.GL_TEXTURE_WRAP_S.toString(16))
                        }
    
                        var wrapModeS:String = (textureParams.GL_TEXTURE_WRAP_S == GL_REPEAT) ? "repeat" : "clamp"
                        fragmentShader = _fragmentShader_Texture.replace("wrapMode", wrapModeS)

                        if(log) log.send("mipmapping levels " + ti.mipLevels)

                        if (ti.mipLevels > 1) {
                            fragmentShader = fragmentShader.replace("minFilter", "linear, miplinear, -2.0")
                        } else if(textureParams.GL_TEXTURE_MIN_FILTER == GL_NEAREST) {
                            fragmentShader = fragmentShader.replace("minFilter", "nearest")
                        } else {
                            fragmentShader = fragmentShader.replace("minFilter", "linear")
                        }
                    }
                }
                else
                {
                    if (log) log.send("using color shaders...")
                    vertexShader = _vertexShader_Color
                    p.vertexStreamUsageFlags = _vertexShader_Color_Flags
                    fragmentShader = _fragmentShader_Color
                }
                
                // CALCULATE VERTEX COLOR
                var useVertexColor:Boolean = (0 != (flags & VertexBufferBuilder.HAS_COLOR))
                if (useVertexColor)
                    p.vertexStreamUsageFlags |= VertexBufferBuilder.HAS_COLOR
                
                if (contextEnableLighting)
                {
                    
                    // va0 - position
                    // va1 - color
                    // va2 - normal
                    // va3 - texture coords
                    //
                    // vc0,1,2,3 - modelViewProjection
                    // vc4,5,6,7 - modelView
                    // vc8,9,10,11 - inverse modelView
                    // vc12, 13, 14, 15 - texture matrix
                    // vc16 - (0, 0.5, 1.0, 2.0)
                    // vc17 - current color state (to be used when vertex color is not specified)
                    // vc18-vc23 - clipPlanes
                    // vc24 - viewpoint (origin of eyespace)
                    // vc25 - mat_ambient
                    // vc26 - mat_diffuse
                    // vc27 - mat_specular
                    // vc28 - mat_shininess (in the form [shininess, 0, 0, 0])
                    // vc29 - mat_emission
                    // vc30 - global ambient lighting
                    // vc31 - light 0 position (in eye-space)
                    // vc32 - light 0 ambient
                    // vc33 - light 0 diffuse
                    // vc34 - light 0 specular
                    // vc35-38 - light 1
                    // vc39-42 - light 2
                    // vc43-46 - light 3
                    // vc47-50 - light 4
                    // vc51-54 - light 5
                    // vc55-58 - light 6
                    // vc59-62 - light 7
                    //
                    // v6, v7 - reserved for clipping
                    
                    // vertex color = 
                    //    emissionmaterial + 
                    //    ambientlight model * ambientmaterial +
                    //    [ambientlight *ambientmaterial +
                    //     (max { L · n , 0} ) * diffuselight * diffusematerial +
                    //     (max { s · n , 0} )shininess * specularlight * specularmaterial ] per light. 
                    // vertex alpha = diffuse material alpha
                    
                    p.vertexStreamUsageFlags |= VertexBufferBuilder.HAS_NORMAL
                    
                    // matColorReg == ambient and diffuse material color to use
                    var matAmbReg:String = (contextColorMaterial) ?
                                                ((useVertexColor) ? "va1" : "vc17") : "vc25"
                    var matDifReg:String = (contextColorMaterial) ? 
                                                ((useVertexColor) ? "va1" : "vc17") : "vc26"
                    
                    // FIXME (klin): Need to refactor to take into account multiple lights...
                    /*var lightingShader:String = [
                        "mov vt0, vc29",                   // start with emission material
                        "add vt0, vt0, " + matAmbReg,      // add ambient material color
                        "add vt0, vt0, " + matDifReg,      // add diffuse material color
                        "mov vt0.w, " + matDifReg + ".w",  // alpha = diffuse material alpha
                        "sat vt0, vt0",                    // clamp to 0 or 1
                        "mov v5, vt0",
                    ].join("\n")*/
                    
                    // v5 = vt3 will be used to calculate the final color.
                    // v4 = vt7 is the specular color if contextSeparateSpecular == true
                    //      otherwise, specular is included in v5.
                    var lightingShader:String = [
                        // init v4 to 0
                        "mov v4.xyzw, vc16.xxxx",
                        
                        // calculate some useful constants
                        // vt0 = vertex in eye space
                        // vt1 = normalized normal vector in eye space
                        // vt2 = |V| = normalized vector from origin of eye space to vertex
                        "m44 vt0, va0, vc4",               // vt0 = vertex in eye space
                        "mov vt1, va2",                    // vt1 = normal vector
                        "m33 vt1.xyz, vt1, vc4",           // vt1 = normal vector in eye space
                        "nrm vt1.xyz, vt1",                // vt1 = n = norm(normal vector)
                        "neg vt2, vt0",                    // vt2 = V = origin - vertex in eye space  
                        "nrm vt2.xyz, vt2",                // vt2 = norm(V)
                        
                        // general lighting
                        "mov vt3, vc29",                   // start with emission material
                        "mov vt4, vc30",                   // vt4 = global ambient light
                        "mul vt4, vt4, " + matAmbReg,      // global ambientlight model * ambient material
                        "add vt3, vt3, vt4",               // add ambient color from global light
                        
                        // Light specific calculations
                        
                        // Initialize temp for specular
                        "mov vt7, vc16.xxxx",              // vt7 is specular, will end in v4
                        
                        //   ambient color
//                        "mov vt4, vc32",
//                        "mul vt4, vt4, " + matAmbReg,      // ambientlight0 * ambientmaterial
//                        "add vt3, vt3, vt4",               // add ambient color from light0
//                        
//                        //   diffuse color
//                        "sub vt4, vc31, vt0",              // vt4 = L = light0 pos - vertex pos
//                        "nrm vt4.xyz, vt4",                // vt4 = norm(L)
//                        "mov vt5, vt1",
//                        "dp3 vt5.x, vt4, vt5",             // vt5.x = L · n
//                        "max vt5.x, vt5.x, vc16.x",        // vt5.x = max { L · n , 0}
//                        "neg vt6.x, vt5.x",                // check if L · n is <= 0 
//                        "slt vt6.x, vt6.x, vc16.x",
//                        "mul vt5.xyz, vt5.xxx, vc33.xyz",  // vt5 = vt5.x * diffuselight0
//                        "mul vt5, vt5, " + matDifReg,      // vt0 = vt0 * diffusematerial
//                        "add vt3, vt3, vt5",               // add diffuse color from light0
//                        
//                        //   specular color
//                        "add vt5, vt4, vt2",               // vt5 = s = L + V
//                        "nrm vt5.xyz, vt5",                // vt5 = norm(s)
//                        "dp3 vt5.x, vt5, vt1",             // vt5.x = s · n
//                        "max vt5.x, vt5.x, vc16.x",        // vt5.x = max { s · n , 0}
//                        "pow vt5.x, vt5.x, vc28.x",        // vt5.x = max { s · n , 0}^shininess
//                        "max vt5.x, vt5.x, vc16.x",        // make sure vt5 is not negative.
//                        "mul vt5.xyz, vt5.xxx, vc34.xyz",  // vt5 = vt5.x * specularlight0
//                        "mul vt5, vt5, vc27",              // vt5 = vt5 * specularmaterial
//                        "mul vt5, vt5.xyz, vt6.xxx",       // specular = 0 if L · n is <= 0.
                        
//                        "sat vt5, vt5",
//                        "mov v4, vt5",                     // specular is separate and added later.
//
//                        //"add vt3, vt3, vt5",               // add specular color from light0
//                        
//                        // alpha determined by diffuse material
//                        "mov vt3.w, " + matDifReg + ".w",  // alpha = diffuse material alpha
//                        
//                        "sat vt3, vt3",                    // clamp to 0 or 1
//                        "mov v5, vt3",                     // v5 = final color
                    ].join("\n")
                    
                    if (!lightsEnabled[0] && !lightsEnabled[1])
                        if (log) log.send("GL_LIGHTING enabled, but no lights are enabled...")
                    
                    // concatenate shader for each light
                    for (var i:int = 0; i < 8; i++)
                    {
                        if (!lightsEnabled[i])
                            continue
                        
                        var l:Light = lights[i]
                        var starti:int = 31 + i*4
                        var lpos:String = "vc" + starti.toString()
                        var lamb:String = "vc" + (starti+1).toString()
                        var ldif:String = "vc" + (starti+2).toString()
                        var lspe:String = "vc" + (starti+3).toString()
                        
                        var lightpiece:String = [
                            //   ambient color
                            "mov vt4, " + lamb,
                            "mul vt4, vt4, " + matAmbReg,      // ambientlight0 * ambientmaterial
                            "add vt3, vt3, vt4",               // add ambient color from light0
                            
                            //   diffuse color
                            "sub vt4, " + lpos + ", vt0",      // vt4 = L = light0 pos - vertex pos
                            "nrm vt4.xyz, vt4",                // vt4 = norm(L)
                            "mov vt5, vt1",
                            "dp3 vt5.x, vt4, vt5",             // vt5.x = L · n
                            "max vt5.x, vt5.x, vc16.x",        // vt5.x = max { L · n , 0}
                            "neg vt6.x, vt5.x",                // check if L · n is <= 0 
                            "slt vt6.x, vt6.x, vc16.x",
                            "mul vt5.xyz, vt5.xxx, " + ldif + ".xyz",  // vt5 = vt5.x * diffuselight0
                            "mul vt5, vt5, " + matDifReg,      // vt0 = vt0 * diffusematerial
                            "add vt3, vt3, vt5",               // add diffuse color from light0
                            
                            //   specular color
                            "add vt5, vt4, vt2",               // vt5 = s = L + V
                            "nrm vt5.xyz, vt5",                // vt5 = norm(s)
                            "dp3 vt5.x, vt5, vt1",             // vt5.x = s · n
                            "max vt5.x, vt5.x, vc16.x",        // vt5.x = max { s · n , 0}
                            "pow vt5.x, vt5.x, vc28.x",        // vt5.x = max { s · n , 0}^shininess
                            "max vt5.x, vt5.x, vc16.x",        // make sure vt5 is not negative.
                            "mul vt5.xyz, vt5.xxx, " + lspe + ".xyz",  // vt5 = vt5.x * specularlight0
                            "mul vt5, vt5, vc27",              // vt5 = vt5 * specularmaterial
                            "mul vt5, vt5.xyz, vt6.xxx",       // specular = 0 if L · n is <= 0.
                            "add vt7, vt7, vt5",               // add specular to output (will be in v4)
                        ].join("\n")
                        
                        lightingShader = lightingShader + "\n" + lightpiece
                    }
                    
                    lightingShader = lightingShader + "\n" + [
                        "sat vt7, vt7",
                        "mov v4, vt7",                     // specular is separate and added later.

                        // alpha determined by diffuse material
                        "mov vt3.w, " + matDifReg + ".w",  // alpha = diffuse material alpha
                        
                        "sat vt3, vt3",                    // clamp to 0 or 1
                        "mov v5, vt3",                     // v5 = final color
                    ].join("\n")
                    
                    if (useVertexColor)
                        lightingShader = "mov vt0, va1\n" + lightingShader //HACK
                    vertexShader = lightingShader + "\n" + vertexShader
                }
                else if (useVertexColor)
                {
                    // Color should come from the vertex buffer
                    // also init v4 to 0.
                    vertexShader = "mov v4.xyzw, vc16.xxxx\n" + "mov v5, va1" + "\n" + vertexShader
                }
                else
                {
                    // Color should come form the current color
                    // also init v4 to 0.
                    vertexShader = "mov v4.xyzw, vc16.xxxx\n" + "mov v5, vc17" + "\n" + vertexShader
                }
                
                
                // CLIPPING
                var clippingOn:Boolean = clipPlaneEnabled[0] || clipPlaneEnabled[1] || clipPlaneEnabled[2] || clipPlaneEnabled[3] || clipPlaneEnabled[4] || clipPlaneEnabled[5]
                if (clippingOn)
                {
                    // va0 - position
                    // va1 - color
                    // va2 - normal
                    // va3 - texture coords
                    //
                    // vc0,1,2,3 - modelViewProjection
                    // vc4,5,6,7 - modelView
                    // vc8,9,10,11 - inverse modelView
                    // vc12, 13, 14, 15 - texture matrix
                    // vc16 - (0, 0.5, 1.0, 2.0)
                    // vc17 - current color state (to be used when vertex color is not specified)
                    // vc18 - clipPlane0 
                    // vc19 - clipPlane1 
                    // vc20 - clipPlane2 
                    // vc21 - clipPlane3 
                    // vc22 - clipPlane4 
                    // vc23 - clipPlane5
                    //
                    // v6, v7 - reserved for clipping
                    
                    // For all Fragment shaders 
                    //
                    // v6 - dot(clipPlane0, pos), dot(clipPlane1, pos), dot(clipPlane2, pos), dot(clipPlane3, pos) 
                    // v7 - dot(clipPlane4, pos), dot(clipPlane5, pos) 
                    //
                    const clipVertex:String = [
                        "m44 vt0, va0, vc4",        // position in eye (modelVeiw) space
                        "dp4 v6.x, vt0, vc18",       // calculate clipPlane0 
                        "dp4 v6.y, vt0, vc19",       // calculate clipPlane1 
                        "dp4 v6.z, vt0, vc20",       // calculate clipPlane2 
                        "dp4 v6.w, vt0, vc21",       // calculate clipPlane3 
                        "dp4 v7.x, vt0, vc22",       // calculate clipPlane4 
                        "dp4 v7.yzw, vt0, vc23",       // calculate clipPlane5 
                    ].join("\n")

                    const clipFragment:String = [
                        "min ft0.x, v6.x, v6.y",
                        "min ft0.y, v6.z, v6.w",
                        "min ft0.z, v7.x, v7.y",
                        "min ft0.w, ft0.x, ft0.y",
                        "min ft0.w, ft0.w, ft0.z",
                        "kil ft0.w",
                    ].join("\n")

                    vertexShader = clipVertex + "\n" + vertexShader
                    fragmentShader = clipFragment + "\n" + fragmentShader
                }

                if(log) {
                log.send("vshader:\n" + vertexShader)
                log.send("fshader:\n" + fragmentShader)
                }

                // FIXME (egeorgie): cache the agalcode?
                var vsAssembler:AGALMiniAssembler = new AGALMiniAssembler
                vsAssembler.assemble(Context3DProgramType.VERTEX, vertexShader)
                var fsAssembler:AGALMiniAssembler = new AGALMiniAssembler
                fsAssembler.assemble(Context3DProgramType.FRAGMENT, fragmentShader)
                p.program.upload(vsAssembler.agalcode, fsAssembler.agalcode)
            }
            return p
        }

        //extern void glVertex3fv (const GLfloat *v)
        public function glVertex(x:Number, y:Number, z:Number):void
        {
            //vbb.pos.push(x, y, z)
            vbb.x = x
            vbb.y = y
            vbb.z = z

            if (log)
            {
                if ((vbb.flags & VertexBufferBuilder.HAS_TEXTURE2D) != 0)
                    log.send("glVertex("+ x + ", " + y + ", " + z + ", tx = " + vbb.tx + ", ty = " + vbb.ty + ")")
                else 
                    log.send("glVertex("+ x + ", " + y + ", " + z + ")")
            }
            
            vbb.push()
        }
        
        private var contextColor:Vector.<Number> = new <Number>[1, 1, 1, 1]
        
        public function glColor(r:Number, g:Number, b:Number, alpha:Number):void
        {
            //if (log) log.send("glColor")

            if (vbb)
            {
                vbb.r = r
                vbb.g = g
                vbb.b = b
                vbb.a = alpha
                vbb.flags |= VertexBufferBuilder.HAS_COLOR
            }
        
            // Change current color if we're not recording a command
            if (!activeCommandList)
            {
                contextColor[0] = r                
                contextColor[1] = g                
                contextColor[2] = b                
                contextColor[3] = alpha                
            }
            
            //if (alpha < 1)
            //    if (log) log.send("Color: " + r + ", " + g + ", " + b + ", " + alpha) 
        }
        
        public function glTexCoord(x:Number, y:Number):void
        {
            if (log) log.send("glTexCoord")
            vbb.tx = x
            vbb.ty = y
            vbb.flags |= VertexBufferBuilder.HAS_TEXTURE2D
        }
        
        public function glNormal(x:Number, y:Number, z:Number):void
        {
            if (log) log.send("glNormal")
            vbb.nx = x
            vbb.ny = y
            vbb.nz = z
            vbb.flags |= VertexBufferBuilder.HAS_NORMAL
        }

        /* ListMode */
        public static const GL_COMPILE:uint = 0x1300
        public static const GL_COMPILE_AND_EXECUTE:uint = 0x1301
        
        public function glNewList(id:uint, mode:uint):void
        {
            // Allocate and active a new CommandList
            if (log) log.send("glNewList : " + id + ", compileAndExecute = " + (mode == GL_COMPILE_AND_EXECUTE).toString())
            activeCommandList = new CommandList()
            activeCommandList.executeOnCompile = (mode == GL_COMPILE_AND_EXECUTE)
            commandLists[id] = activeCommandList
        }
        
        //extern void glEndList (void)
        public function glEndList():void
        {
            // Make sure if we have any pending state changes, we push them as a command at the end of the list
            if (activeCommandList.activeState)
            {
                activeCommandList.commands.push(activeCommandList.activeState)
                activeCommandList.activeState = null
            }
            
            if (activeCommandList.executeOnCompile)
                executeCommandList(activeCommandList)
            
            // We're done with this list, it's no longer active
            activeCommandList = null
        }
        
        //extern void glCallList (GLuint list)
        public function glCallList(id:uint):void
        {
            if (log) log.send("glCallList")
            if (activeCommandList)
                if (log) log.send("Warning: Calling a command list while building a command list not yet implemented.")
            
            if (!lsitDisabled[id])
            {
                if (log) log.send("Rendering List " + id)
                executeCommandList(commandLists[id])
            }
            else
                if (log) log.send("skipping list " + id)
        }

        
        // ======================================================================
        //  Properties
        // ----------------------------------------------------------------------
        
        public var log:Object = null; // new TraceLog();
        public var context:Context3D
        private var contextWidth:int = 0
        private var contextHeight:int = 0
        private var contextAA:int = 0
        private var contextClearR:Number
        private var contextClearG:Number
        private var contextClearB:Number
        private var contextClearA:Number
        private var contextClearDepth:Number = 1.0
        private var contextClearStencil:uint = 0
        private var contextClearMask:uint
        private var contextEnableStencil:Boolean = false
        private var contextEnableAlphaTest:Boolean = false

        private var contextStencilActionStencilFail:String = Context3DStencilAction.KEEP
        private var contextStencilActionDepthFail:String = Context3DStencilAction.KEEP
        private var contextStencilActionPass:String = Context3DStencilAction.KEEP
        private var contextStencilCompareMode:String = Context3DCompareMode.ALWAYS

        private var contextEnableDepth:Boolean = true
        private var contextDepthMask:Boolean = true
        private var contextSrcBlendFunc:String = Context3DBlendFactor.ZERO
        private var contextDstBlendFunc:String = Context3DBlendFactor.ONE
        private var contextEnableCulling:Boolean
        private var contextEnableBlending:Boolean
//        private var contextFrontFace:uint = GL_CCW
        private var contextDepthFunc:String = Context3DCompareMode.ALWAYS
        private var contextEnableTextures:Boolean = false
        private var contextEnableLighting:Boolean = false
        private var contextColorMaterial:Boolean = false
        private var contextSeparateSpecular:Boolean = false
        private var contextEnablePolygonOffset:Boolean = false
        
        private var needClear:Boolean = true
        private var vertexAttributesDirty:Boolean = true
        //private var macroAssembler:AGALMacroAssembler
        
        private var dataBuffers:Dictionary = new Dictionary()
        private var frameBuffers:Dictionary = new Dictionary()
        private var renderBuffers:Dictionary = new Dictionary()
        private var programs:Dictionary = new Dictionary()
        private var shaders:Dictionary = new Dictionary()
        private var textures:Dictionary = new Dictionary()
        private var vertexBufferAttributes:Vector.<VertexBufferAttribute> = new Vector.<VertexBufferAttribute>(8)
        private var textureUnits:Array = new Array(32)
        public var activeProgram:ProgramInstance
        private var activeTextureUnit:uint = 0
        private var activeArrayBuffer:DataBuffer
        private var activeElementBuffer:DataBuffer
        private var pendingFrameBuffer:FrameBuffer
        private var activeFrameBuffer:FrameBuffer
        private var activeRenderBuffer:RenderBuffer

        // FIXME (egeorgie): Single activeTexture of type TextureInstance or just id to the istance?
//        private var active2DTexture:TextureParams
//        private var activeCubeTexture:TextureParams
        private var activeTexture:TextureInstance

        private var textureSamplers:Vector.<TextureInstance> = new Vector.<TextureInstance>(8)
        private var textureSamplerIDs:Vector.<uint> = new Vector.<uint>(8)

        private var framestamp:uint = 1
        private var vertexBufferPool:Dictionary = new Dictionary()
        private var indexBufferPool:Dictionary = new Dictionary()
        private var squentialTripStripIndexBufferPool:Dictionary = new Dictionary()
        
        public var dumpShaderCode:Boolean = false

        public var genOnBind:Boolean = false

    //public var counts:Dictionary = new Dictionary()

        // ======================================================================
        //  Constants
        // ----------------------------------------------------------------------       
        public static const GL_DEPTH_BUFFER_BIT:uint    = 0x00000100
        public static const GL_STENCIL_BUFFER_BIT:uint = 0x00000400
        public static const GL_COLOR_BUFFER_BIT:uint    = 0x00004000
        
        public static const GL_ALPHA_TEST:uint      = 0x0BC0
        public static const GL_DITHER:uint          = 0x0BD0
        public static const GL_BLEND:uint           = 0x0BE2
        public static const GL_STENCIL_TEST:uint    = 0x0B90
        public static const GL_SCISSOR_TEST:uint    = 0x0C11
        public static const GL_DEPTH_TEST:uint      = 0x0B71
        public static const GL_CULL_FACE:uint       = 0x0B44
        public static const GL_NORMALIZE:uint       = 0x0BA1
        
//        public static const GL_CW:uint  = 0x0900
//        public static const GL_CCW:uint = 0x0901
        
//        public static const GL_NEVER:uint       = 0x0200
//        public static const GL_LESS:uint        = 0x0201
//        public static const GL_EQUAL:uint       = 0x0202
//        public static const GL_LEQUAL:uint      = 0x0203
//        public static const GL_GREATER:uint     = 0x0204
//        public static const GL_NOTEQUAL:uint    = 0x0205
//        public static const GL_GEQUAL:uint      = 0x0206
//        public static const GL_ALWAYS:uint      = 0x0207
        
        public static const GL_ZERO:uint                    = 0x0
        public static const GL_ONE:uint                     = 0x1
        public static const GL_SRC_COLOR:uint               = 0x0300
        public static const GL_ONE_MINUS_SRC_COLOR:uint     = 0x0301
        public static const GL_SRC_ALPHA:uint               = 0x0302
        public static const GL_ONE_MINUS_SRC_ALPHA:uint     = 0x0303
        public static const GL_DST_ALPHA:uint               = 0x0304
        public static const GL_ONE_MINUS_DST_ALPHA:uint     = 0x0305
        public static const GL_DST_COLOR:uint                = 0x0306
        public static const GL_ONE_MINUS_DST_COLOR:uint        = 0x0307
        public static const GL_FUNC_ADD:uint                = 0x8006
        
        public static const GL_TEXTURE0:uint                    = 0x84C0
        public static const GL_ACTIVE_TEXTURE:uint              = 0x84E0
        public static const GL_TEXTURE_2D:uint                  = 0x0DE1
        public static const GL_TEXTURE_CUBE_MAP:uint            = 0x8513
        public static const GL_TEXTURE_MAX_ANISOTROPY_EXT:uint  = 0x84FE
        public static const GL_TEXTURE_MAG_FILTER:uint          = 0x2800
        public static const GL_TEXTURE_MIN_FILTER:uint          = 0x2801

        public static const GL_TEXTURE_MIN_LOD:uint          = 0x813A
        public static const GL_TEXTURE_MAX_LOD:uint          = 0x813B
        
        public static const GL_TEXTURE_CUBE_MAP_POSITIVE_X:uint    = 0x8515
        public static const GL_TEXTURE_CUBE_MAP_NEGATIVE_X:uint    = 0x8516
        public static const GL_TEXTURE_CUBE_MAP_POSITIVE_Y:uint    = 0x8517
        public static const GL_TEXTURE_CUBE_MAP_NEGATIVE_Y:uint    = 0x8518
        public static const GL_TEXTURE_CUBE_MAP_POSITIVE_Z:uint    = 0x8519
        public static const GL_TEXTURE_CUBE_MAP_NEGATIVE_Z:uint    = 0x851A
        public static const GL_LUMINANCE:uint                      = 0x1909
        
        public static const GL_ARRAY_BUFFER:uint            = 0x8892
        public static const GL_ELEMENT_ARRAY_BUFFER:uint    = 0x8893
        
        public static const GL_STREAM_DRAW:uint   = 0x88E0
        public static const GL_STATIC_DRAW:uint   = 0x88E4
        public static const GL_DYNAMIC_DRAW:uint  = 0x88E8
        
        public static const GL_FRAGMENT_SHADER:uint  = 0x8B30
        public static const GL_VERTEX_SHADER:uint    = 0x8B31
        
        public static const GL_UNSIGNED_BYTE:uint   = 0x1401
        public static const GL_UNSIGNED_SHORT:uint  = 0x1403
        public static const GL_FLOAT:uint           = 0x1406
        
        public static const CDATA_FLOAT1:uint        = 1
        public static const CDATA_FLOAT2:uint        = 2
        public static const CDATA_FLOAT3:uint        = 3
        public static const CDATA_FLOAT4:uint        = 4
        public static const CDATA_MATRIX4x4:uint     = 16
        
        public static const GL_COMPRESSED_RGB_PVRTC_2BPPV1_IMG:uint = 0x83F0
                
        // ----------------------------------------------------------------------
        //
        //  Constructor
        //
        // ----------------------------------------------------------------------

        public function GLAPI(context:Context3D, log:Object, stage:Stage):void
        {
            // For the debug console
            _stage = stage
            _stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown_handler, false, 0)
            
            //this.log = new TraceLog()
            this.context = context
            indexBufferCache = acquireBufferFromPool(65536, 0, GL_ELEMENT_ARRAY_BUFFER)
            indexBufferCache.indicesSize = GL_UNSIGNED_SHORT

            for (var i:int = 0; i < 65536; i++)
                indexBufferCache.data.writeShort(i)
            indexBufferCache.size = 65536
            uploadBuffer(indexBufferCache)

            indexBufferQuadCache.endian = "littleEndian"
            indexBufferQuadCache.writeShort(0)
            indexBufferQuadCache.writeShort(1)
            indexBufferQuadCache.writeShort(2)
            indexBufferQuadCache.writeShort(2)
            indexBufferQuadCache.writeShort(1)
            indexBufferQuadCache.writeShort(3)
        }
        
        // ----------------------------------------------------------------------
        //
        //  Methods
        //
        // ----------------------------------------------------------------------
        
        public function glClear(mask:uint):void
        {
            if (log) log.send( "glClear called with " + mask)

            // trace("validateFramebufferState from glClear")
            validateFramebufferState(false)

            contextClearMask = 0
            if (mask & GL_COLOR_BUFFER_BIT) contextClearMask |= Context3DClearMask.COLOR
            if (mask & GL_STENCIL_BUFFER_BIT) contextClearMask |= Context3DClearMask.STENCIL
            if (mask & GL_DEPTH_BUFFER_BIT) contextClearMask |= Context3DClearMask.DEPTH
            
            if (bgColorOverride)
            {
                context.clear(overrideR / 255.0, overrideG / 255.0, overrideB / 255.0, overrideA / 255.0,
                    contextClearDepth, contextClearStencil, contextClearMask)
            }
            else
            {
                context.clear(contextClearR, contextClearG, contextClearB, contextClearA,
                    contextClearDepth, contextClearStencil, contextClearMask)
            }

            // If this is a render texture, keep track of the last frame it was cleared
            if (activeFrameBuffer != null)
            {
                // trace( "    clear targeted an offscreen texture")
                activeFrameBuffer.lastClearFramestamp = framestamp
            }

            // Make sure the vertex buffer pool knows it's next frame already to enable recycling
            immediateVertexBuffers.nextFrame()
        }
        
        public function glClearColor(red:Number, green:Number, blue:Number, alpha:Number):void
        {
            if (log) log.send("[IMPLEMENTED] glClearColor " + red + " " + green + " " + blue + " " + alpha + "\n")
    
            contextClearR = red
            contextClearG = green
            contextClearB = blue
            contextClearA = alpha
        }
        
        public function glFinish():void
        {
            // log.send( "[STUBBED] glFinish\n")
        }
        
        public function glActiveTexture(index:uint):void
        {
            var unitIndex:uint = index - GL_TEXTURE0
            if(unitIndex <= 31) {
                activeTextureUnit = unitIndex
                // log.send( "[IMPLEMENTED] glActiveTexture " + activeTextureUnit + "\n")
            } else {
                // log.send( "[NOTE] Invalid texture unit requested " + uint)
            }
        }
        
        public function glFlush():void
        {
            // log.send( "[STUBBED] glFlush\n")
        }
        
        public function glBindTexture(type:uint, texture:uint):void
        {
            textureSamplerIDs[activeTextureUnit] = texture

            if(genOnBind){
                if(textures[texture] == null) {
                    textures[texture] = new TextureInstance()
                    textures[texture].texID = texture
                }
            } else if (texture == 0) {
                // FIXME (egeorgie): just set the sampler to null and clear the active texture params?
                if (log) log.send("Trying bind the non-existent texture 0!")
                return
            }
            
            if (log) log.send( "[IMPLEMENTED] glBindTexture " + type + " " + texture + ", tu: " + activeTextureUnit + "\n")

            if (activeCommandList)
            {
                if (log) log.send("Recording texture " + texture + " for the active list.")
                
                var activeState:ContextState = activeCommandList.ensureActiveState()                
                activeState.textureSamplers[activeTextureUnit] = texture
                
                // FIXME (egeorgie): we should not execute here, but only while executing the lsit
                // return
            }
            
            activeTexture = textures[texture]
            activeTexture.boundType = type
            textureSamplers[activeTextureUnit] = activeTexture
            
            if (type != GL_TEXTURE_2D && type != GL_TEXTURE_CUBE_MAP)
            {
                if (log) log.send( "[NOTE] Unsupported texture type " + type + " for glBindTexture")
            }
        }
        
        
        //void glCullFace(GLenum  mode)
        /* CullFaceMode */
        /*      GL_FRONT */
        /*      GL_BACK */
        /*      GL_FRONT_AND_BACK */
        public static const GL_FRONT:uint =             0x0404
        public static const GL_BACK:uint =              0x0405
        public static const GL_FRONT_AND_BACK:uint =    0x0408

        private function glCullModeToContext3DTriangleFace(mode:uint, frontFaceClockWise:Boolean):String
        {
            switch (mode)
            {
                case GL_FRONT: //log.send("culling=GL_FRONT") 
                    return frontFaceClockWise ? Context3DTriangleFace.FRONT : Context3DTriangleFace.BACK
                case GL_BACK: //log.send("culling=GL_BACK")
                    return frontFaceClockWise ? Context3DTriangleFace.BACK : Context3DTriangleFace.FRONT
                case GL_FRONT_AND_BACK: //log.send("culling=GL_FRONT_AND_BACK")
                    return Context3DTriangleFace.FRONT_AND_BACK
                default:
                    if (log) log.send("Unsupported glCullFace mode: 0x" + mode.toString(16))
                    return Context3DTriangleFace.NONE
            }
        }

        public function glCullFace(mode:uint):void
        {
            if (log) log.send("glCullFace")

            if (activeCommandList)
                if (log) log.send("[Warning] Recording glCullMode as part of command list not yet implememnted")
            
            this.glCullMode = mode

            // culling affects the context3D stencil 
            commitStencilState()
            
            if (contextEnableCulling)
                context.setCulling(disableCulling ? Context3DTriangleFace.NONE: glCullModeToContext3DTriangleFace(glCullMode, frontFaceClockWise))         
        }
        
        
        /* FrontFaceDirection */
        public static const GL_CW:uint =    0x0900
        public static const GL_CCW:uint =   0x0901

        
        // Initial value
        private var frontFaceClockWise:Boolean = false // we default to CCW
        private var glCullMode:uint = GL_BACK
        
        public function glFrontFace(mode:uint):void
        {
            if (log) log.send("glFrontFace")

            if (activeCommandList)
                if (log) log.send("[Warning] Recording glFrontFace as part of command list not yet implememnted")
            
            frontFaceClockWise = (mode == GL_CW)
            
            // culling affects the context3D stencil 
            commitStencilState()
            
            if (contextEnableCulling)
                context.setCulling(disableCulling ? Context3DTriangleFace.NONE : glCullModeToContext3DTriangleFace(glCullMode, frontFaceClockWise))         
        }

        public function glEnable(cap:uint):void
        {
            if (log) log.send( "[IMPLEMENTED] glEnable 0x" + cap.toString(16) + "\n")
            switch (cap)
            {
                case GL_DEPTH_TEST:
                    contextEnableDepth = true
                    context.setDepthTest(contextDepthMask, contextDepthFunction)
                    break
                case GL_CULL_FACE:
                    if (!contextEnableCulling)
                    {
                        contextEnableCulling = true
                        context.setCulling(disableCulling ? Context3DTriangleFace.NONE : glCullModeToContext3DTriangleFace(glCullMode, frontFaceClockWise))
                        
                        // Stencil depends on culling
                        commitStencilState()
                    }
                    break
                case GL_STENCIL_TEST:
                    if (!contextEnableStencil)
                    {
                        contextEnableStencil = true
                        commitStencilState()
                    }
                    break
                case GL_SCISSOR_TEST:
                    if (!contextEnableScissor)
                    {
                        contextEnableScissor = true
                        if(!scissorRect)
                            scissorRect = new Rectangle(0,0,contextWidth,contextHeight)

                        context.setScissorRectangle(scissorRect)
                    }
                    break
                case GL_ALPHA_TEST:
                    if (!contextEnableAlphaTest)
                    {
                        contextEnableAlphaTest = true
                    }
                    break
                case GL_BLEND:
                    contextEnableBlending = true
                    if(!disableBlending)
                        context.setBlendFactors(contextSrcBlendFunc, contextDstBlendFunc)
                    break
                
                case GL_TEXTURE_GEN_S:
                    enableTexGenS = true
                break
                
                case GL_TEXTURE_GEN_T:
                    enableTexGenT = true
                break
                
                case GL_CLIP_PLANE0:
                case GL_CLIP_PLANE1:
                case GL_CLIP_PLANE2:
                case GL_CLIP_PLANE3:
                case GL_CLIP_PLANE4:
                case GL_CLIP_PLANE5:
                    var clipPlaneIndex:int = cap - GL_CLIP_PLANE0
                    clipPlaneEnabled[clipPlaneIndex] = true
                    setGLState(ENABLE_LIGHT_OFFSET + clipPlaneIndex)
                break
                
                case GL_TEXTURE_2D:
                    contextEnableTextures = true
                    setGLState(ENABLE_TEXTURE_OFFSET)
                    break
                
                case GL_LIGHTING:
                    contextEnableLighting = true
                    setGLState(ENABLE_LIGHTING_OFFSET)
                    break
                
                case GL_COLOR_MATERIAL:
                    contextColorMaterial = true // default is GL_FRONT_AND_BACK and GL_AMBIENT_AND_DIFFUSE
                    setGLState(ENABLE_COLOR_MATERIAL_OFFSET)
                    break
                
                case GL_LIGHT0:
                case GL_LIGHT1:
                case GL_LIGHT2:
                case GL_LIGHT3:
                case GL_LIGHT4:
                case GL_LIGHT5:
                case GL_LIGHT6:
                case GL_LIGHT7:
                    var lightIndex:int = cap - GL_LIGHT0
                    if (lights[lightIndex] == null)
                    {
                        lights[lightIndex] = new Light(true, lightIndex == 0)
                    }
                    lightsEnabled[lightIndex] = true
                    setGLState(ENABLE_LIGHT_OFFSET + lightIndex)
                    break
                
                case GL_POLYGON_OFFSET_FILL:
                    contextEnablePolygonOffset = true
                    setGLState(ENABLE_POLYGON_OFFSET)
                    break
                
                default:
                    if (log) log.send( "[NOTE] Unsupported cap for glEnable: 0x" + cap.toString(16) )
            }
        }
        
        public function glDisable(cap:uint):void
        {
            if (log) log.send( "[IMPLEMENTED] glDisable 0x" + cap.toString(16) + "\n")
            switch (cap)
            {
                case GL_DEPTH_TEST:
                    contextEnableDepth = false
                    context.setDepthTest(false, Context3DCompareMode.ALWAYS)
                    break
                case GL_CULL_FACE:
                    if (contextEnableCulling)
                    {
                        contextEnableCulling = false
                        context.setCulling(Context3DTriangleFace.NONE)

                        // Stencil depends on culling
                        commitStencilState()
                    }
                    break
                case GL_STENCIL_TEST:
                    if (contextEnableStencil)
                    {
                        contextEnableStencil = false
                        commitStencilState()
                    }
                    break
                case GL_SCISSOR_TEST:
                    if (contextEnableScissor)
                    {
                        contextEnableScissor = false
                        context.setScissorRectangle(new Rectangle(0,0,contextWidth,contextHeight))
                    }
                    break
                case GL_ALPHA_TEST:
                    if (!contextEnableAlphaTest)
                    {
                        contextEnableAlphaTest = false
                    }
                    break
                case GL_BLEND:
                    contextEnableBlending = false
                    if(!disableBlending)
                        context.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO)
                    break

                case GL_TEXTURE_GEN_S:
                    enableTexGenS = false
                    break
                
                case GL_TEXTURE_GEN_T:
                    enableTexGenT = false
                    break

                case GL_CLIP_PLANE0:
                case GL_CLIP_PLANE1:
                case GL_CLIP_PLANE2:
                case GL_CLIP_PLANE3:
                case GL_CLIP_PLANE4:
                case GL_CLIP_PLANE5:
                    var clipPlaneIndex:int = cap - GL_CLIP_PLANE0
                    clipPlaneEnabled[clipPlaneIndex] = false
                    clearGLState(ENABLE_LIGHT_OFFSET + clipPlaneIndex)
                    break
                
               case GL_TEXTURE_2D:
                    contextEnableTextures = false
                    clearGLState(ENABLE_TEXTURE_OFFSET)
                    break
               
               case GL_LIGHTING:
                   contextEnableLighting = false
                   clearGLState(ENABLE_LIGHTING_OFFSET)
                   break
               
               case GL_COLOR_MATERIAL:
                   contextColorMaterial = false // default is GL_FRONT_AND_BACK and GL_AMBIENT_AND_DIFFUSE
                   clearGLState(ENABLE_COLOR_MATERIAL_OFFSET)
                   break
               
               case GL_LIGHT0:
               case GL_LIGHT1:
               case GL_LIGHT2:
               case GL_LIGHT3:
               case GL_LIGHT4:
               case GL_LIGHT5:
               case GL_LIGHT6:
               case GL_LIGHT7:
                   var lightIndex:int = cap - GL_LIGHT0
                   lightsEnabled[lightIndex] = false
                   clearGLState(ENABLE_LIGHT_OFFSET + lightIndex)
                   break
               
               case GL_POLYGON_OFFSET_FILL:
                   contextEnablePolygonOffset = false
                   clearGLState(ENABLE_POLYGON_OFFSET)
                   break
                
                default:
                    if (log) log.send( "[NOTE] Unsupported cap for glDisable: 0x" + cap.toString(16) )
            }
        }

        
        /* AttribMask */
        public static const GL_CURRENT_BIT:uint =                    0x00000001
        public static const GL_POINT_BIT:uint =                      0x00000002
        public static const GL_LINE_BIT:uint =                       0x00000004
        public static const GL_POLYGON_BIT:uint =                    0x00000008
        public static const GL_POLYGON_STIPPLE_BIT:uint =            0x00000010
        public static const GL_PIXEL_MODE_BIT:uint =                 0x00000020
        public static const GL_LIGHTING_BIT:uint =                   0x00000040
        public static const GL_FOG_BIT:uint =                        0x00000080
//        public static const GL_DEPTH_BUFFER_BIT:uint =               0x00000100
        public static const GL_ACCUM_BUFFER_BIT:uint =               0x00000200
//        public static const GL_STENCIL_BUFFER_BIT:uint =             0x00000400
        public static const GL_VIEWPORT_BIT:uint =                   0x00000800
        public static const GL_TRANSFORM_BIT:uint =                  0x00001000
        public static const GL_ENABLE_BIT:uint =                     0x00002000
//        public static const GL_COLOR_BUFFER_BIT:uint =               0x00004000
        public static const GL_HINT_BIT:uint =                       0x00008000
        public static const GL_EVAL_BIT:uint =                       0x00010000
        public static const GL_LIST_BIT:uint =                       0x00020000
        public static const GL_TEXTURE_BIT:uint =                    0x00040000
        public static const GL_SCISSOR_BIT:uint =                    0x00080000
        public static const GL_ALL_ATTRIB_BITS:uint =                0x000fffff

        
        private static const GL_ATTRIB_BIT:Vector.<String> = new <String>[
            "GL_CURRENT_BIT",
            "GL_POINT_BIT",
            "GL_LINE_BIT",
            "GL_POLYGON_BIT",
            "GL_POLYGON_STIPPLE_BIT",
            "GL_PIXEL_MODE_BIT",
            "GL_LIGHTING_BIT",
            "GL_FOG_BIT",
            "GL_DEPTH_BUFFER_BIT",
            "GL_ACCUM_BUFFER_BIT",
            "GL_STENCIL_BUFFER_BIT",
            "GL_VIEWPORT_BIT",
            "GL_TRANSFORM_BIT",
            "GL_ENABLE_BIT",
            "GL_COLOR_BUFFER_BIT",
            "GL_HINT_BIT",
            "GL_EVAL_BIT",
            "GL_LIST_BIT",
            "GL_TEXTURE_BIT",
            "GL_SCISSOR_BIT",
            //"GL_ALL_ATTRIB_BITS",
        ]
        
        
        public function glPushAttrib(mask:uint):void
        {
            if (log) log.send("glPushAttrib + 0x" + mask.toString(16))
            var bits:String = null
            
            for (var i:int = 0; i < GL_ATTRIB_BIT.length; i++)
            {
                if (mask & (1 << i))
                    bits = bits + ", " + GL_ATTRIB_BIT[i]
            }
            
            if (mask & GL_LIGHTING_BIT)
            {
                pushCurrentLightingState()
            }
            
            if (log) log.send( "[NOTE] Unsupported attrib bits " + bits + " for glPushAttrib" )
        }
        
        public function glPopAttrib():void
        {
            // only lighting state for now.
            popCurrentLightingState()         
        }
        
        private var lightingStates:Vector.<LightingState> = new Vector.<LightingState>()
        
        private function pushCurrentLightingState():void
        {
            var lState:LightingState = new LightingState()
            lState.enableColorMaterial = this.contextColorMaterial
            lState.enableLighting = this.contextEnableLighting
            lState.lightsEnabled = this.lightsEnabled.concat()
            
            var newLights:Vector.<Light> = new Vector.<Light>(8)
            var lightsLength:int = this.lights.length
            for (var i:int = 0; i < lightsLength; i++)
            {
                var l:Light = this.lights[i]
                newLights[i] = (l) ? l.createClone() : null
            }
            
            lState.lights = newLights
            lState.contextMaterial = this.contextMaterial.createClone()
            lightingStates.push(lState)
        }
        
        private function popCurrentLightingState():void
        {
            var lState:LightingState = lightingStates.pop()
            this.contextColorMaterial = lState.enableColorMaterial
            this.contextEnableLighting = lState.enableLighting
            this.lightsEnabled = lState.lightsEnabled
            this.lights = lState.lights
            this.contextMaterial = lState.contextMaterial
        }

        // pname
        public static const GL_TEXTURE_WRAP_S:uint = 0x2802
        public static const GL_TEXTURE_WRAP_T:uint = 0x2803
        
        // param
        //GL_CLAMP, GL_CLAMP_TO_BORDER, GL_CLAMP_TO_EDGE, GL_MIRRORED_REPEAT, GL_REPEAT
        public static const GL_CLAMP:uint               = 0x2900
        public static const GL_REPEAT:uint              = 0x2901
        public static const GL_CLAMP_TO_EDGE:uint       = 0x812F
        public static const GL_CLAMP_TO_BORDER:uint     = 0x812D
        public static const GL_MIRRORED_REPEAT:uint     = 0x8370

        public function glTexEnvf(target:uint, pname:uint, param:Number):void
        {
            if (!activeTexture)
            {
                if (log) log.send("[WARNING] Calling glTexEnvf with no active texture")
                return
            }

            var textureParams:TextureParams = activeTexture.params
if (log) log.send("[WARNING] Calling glTexEnvf with unsupported pname " + pname + ", " + param)
            switch(pname)
            {
                case GL_TEXTURE_ENV_MODE:
                    textureParams.GL_TEXTURE_ENV_MODE = param
                    break
                default:
                    if (log) log.send("[WARNING] Calling glTexEnvf with unsupported pname " + pname + ", " + param)
            }
        }

        public function glTexParameterf(target:uint, pname:uint, param:Number):void
        {
            if (log) log.send( "[IMPLEMENTED] glTexParameteri " + target + " 0x" + pname.toString(16) + " 0x" + param.toString(16) + "\n")
            
            if (!activeTexture)
            {
                if (log) log.send("[WARNING] Calling glTexParameteri with no active texture")
                return
            }

            var textureParams:TextureParams = activeTexture.params

            switch (pname)
            {
                case GL_TEXTURE_MIN_LOD:
                    textureParams.GL_TEXTURE_MIN_LOD = param
                break
                case GL_TEXTURE_MAX_LOD:
                    textureParams.GL_TEXTURE_MAX_LOD = param
                break
                case GL_TEXTURE_MIN_FILTER:
                    textureParams.GL_TEXTURE_MIN_FILTER = param
                break
                case GL_TEXTURE_MAG_FILTER:
                    textureParams.GL_TEXTURE_MAG_FILTER = param
                break

                default:
                    if (log) log.send( "[NOTE] Unsupported pname 0x" + pname.toString(16) + " for glTexParameterf" + (target == GL_TEXTURE_2D ? "(2D)" : "(Cube)"))
            }
        }

        public function glTexParameteri(target:uint, pname:uint, param:int):void
        {
            if (log) log.send( "[IMPLEMENTED] glTexParameteri " + target + " 0x" + pname.toString(16) + " 0x" + param.toString(16) + "\n")
            
            if (!activeTexture)
            {
                if (log) log.send("[WARNING] Calling glTexParameteri with no active texture")
                return
            }

            var textureParams:TextureParams = activeTexture.params

            switch (pname)
            {
                case GL_TEXTURE_MAX_ANISOTROPY_EXT:
                    textureParams.GL_TEXTURE_MAX_ANISOTROPY_EXT = param
                break

                case GL_TEXTURE_MAG_FILTER:
                    textureParams.GL_TEXTURE_MAG_FILTER = param
                break
                
                case GL_TEXTURE_MIN_FILTER:
                    textureParams.GL_TEXTURE_MIN_FILTER = param
                break

                case GL_TEXTURE_WRAP_S:
                    textureParams.GL_TEXTURE_WRAP_S = param
                    if (log) log.send("Setting GL_TEXTURE_WRAP_S to: 0x" + param.toString(16)) 
                break
                
                case GL_TEXTURE_WRAP_T:
                    textureParams.GL_TEXTURE_WRAP_T = param
                    if (log) log.send("Setting GL_TEXTURE_WRAP_S to: 0x" + param.toString(16)) 
                break
                
                default:
                    if (log) log.send( "[NOTE] Unsupported pname 0x" + pname.toString(16) + " for glTexParameteri" + (target == GL_TEXTURE_2D ? "(2D)" : "(Cube)"))
            }
        }
        
        
        /* texture */
        // internalFormat
//        #define GL_ALPHA4                         0x803B
//        #define GL_ALPHA8                         0x803C
//        #define GL_ALPHA12                        0x803D
//        #define GL_ALPHA16                        0x803E
//        #define GL_LUMINANCE4                     0x803F
//        #define GL_LUMINANCE8                     0x8040
//        #define GL_LUMINANCE12                    0x8041
//        #define GL_LUMINANCE16                    0x8042
//        #define GL_LUMINANCE4_ALPHA4              0x8043
//        #define GL_LUMINANCE6_ALPHA2              0x8044
//        #define GL_LUMINANCE8_ALPHA8              0x8045
//        #define GL_LUMINANCE12_ALPHA4             0x8046
//        #define GL_LUMINANCE12_ALPHA12            0x8047
//        #define GL_LUMINANCE16_ALPHA16            0x8048
//        #define GL_INTENSITY                      0x8049
//        #define GL_INTENSITY4                     0x804A
//        #define GL_INTENSITY8                     0x804B
//        #define GL_INTENSITY12                    0x804C
//        #define GL_INTENSITY16                    0x804D
//        #define GL_R3_G3_B2                       0x2A10
//        #define GL_RGB4                           0x804F
//        #define GL_RGB5                           0x8050
//        #define GL_RGB8                           0x8051
//        #define GL_RGB10                          0x8052
//        #define GL_RGB12                          0x8053
//        #define GL_RGB16                          0x8054
//        #define GL_RGBA2                          0x8055
//        #define GL_RGBA4                          0x8056
//        #define GL_RGB5_A1                        0x8057
//        #define GL_RGBA8                          0x8058
//        #define GL_RGB10_A2                       0x8059
//        #define GL_RGBA12                         0x805A
//        #define GL_RGBA16                         0x805B
//        #define GL_TEXTURE_RED_SIZE               0x805C
//        #define GL_TEXTURE_GREEN_SIZE             0x805D
//        #define GL_TEXTURE_BLUE_SIZE              0x805E
//        #define GL_TEXTURE_ALPHA_SIZE             0x805F
//        #define GL_TEXTURE_LUMINANCE_SIZE         0x8060
//        #define GL_TEXTURE_INTENSITY_SIZE         0x8061
//        #define GL_PROXY_TEXTURE_1D               0x8063
//        #define GL_PROXY_TEXTURE_2D               0x8064

        
        /* PixelFormat */
        // format 
        public static const GL_COLOR_INDEX:uint =                    0x1900
        public static const GL_STENCIL_INDEX:uint =                  0x1901
        public static const GL_DEPTH_COMPONENT:uint =                0x1902
        public static const GL_RED:uint =                            0x1903
        public static const GL_GREEN:uint =                          0x1904
        public static const GL_BLUE:uint =                           0x1905
        public static const GL_ALPHA:uint =                          0x1906
        public static const GL_RGB:uint =                            0x1907
        public static const GL_RGBA:uint =                           0x1908
//        public static const GL_LUMINANCE:uint =                      0x1909
        public static const GL_LUMINANCE_ALPHA:uint =                0x190A
        
        private static const PIXEL_FORMAT:Array = [
            "GL_COLOR_INDEX",
            "GL_STENCIL_INDEX",
            "GL_DEPTH_COMPONENT",
            "GL_RED",
            "GL_GREEN",
            "GL_BLUE",
            "GL_ALPHA",
            "GL_RGB",
            "GL_RGBA",
        ]
        
        /* PixelType */
        // imgType
        public static const GL_BITMAP:uint =                         0x1A00
        public static const GL_BYTE:uint =                           0x1400
//        public static const GL_UNSIGNED_BYTE:uint =                  0x1401
        public static const GL_SHORT:uint =                          0x1402
//        public static const GL_UNSIGNED_SHORT:uint =                 0x1403
        public static const GL_INT:uint =                            0x1404
        public static const GL_UNSIGNED_INT:uint =                   0x1405
//        public static const GL_FLOAT:uint =                          0x1406
        public static const GL_BGR:uint =                            0x80E0
        public static const GL_BGRA:uint =                           0x80E1
        public static const GL_UNSIGNED_BYTE_3_3_2:uint =            0x8032
        public static const GL_UNSIGNED_SHORT_4_4_4_4:uint =         0x8033
        public static const GL_UNSIGNED_SHORT_5_5_5_1:uint =         0x8034
        public static const GL_UNSIGNED_INT_8_8_8_8:uint =           0x8035
        public static const GL_UNSIGNED_INT_10_10_10_2:uint =        0x8036
        public static const GL_UNSIGNED_BYTE_2_3_3_REV:uint =        0x8362
        public static const GL_UNSIGNED_SHORT_5_6_5:uint =           0x8363
        public static const GL_UNSIGNED_SHORT_5_6_5_REV:uint =       0x8364
        public static const GL_UNSIGNED_SHORT_4_4_4_4_REV:uint =     0x8365
        public static const GL_UNSIGNED_SHORT_1_5_5_5_REV:uint =     0x8366
        public static const GL_UNSIGNED_INT_8_8_8_8_REV:uint =       0x8367
        public static const GL_UNSIGNED_INT_2_10_10_10_REV:uint =    0x8368
        
        private static const PIXEL_TYPE:Array = [
            "GL_BITMAP",
            "GL_BYTE",
            "GL_UNSIGNED_BYTE",
            "GL_SHORT",
            "GL_UNSIGNED_SHORT",
            "GL_INT",
            "GL_UNSIGNED_INT",
            "GL_FLOAT",
            "GL_BGR",
            "GL_BGRA",
            "GL_UNSIGNED_BYTE_3_3_2",
            "GL_UNSIGNED_SHORT_4_4_4_4",
            "GL_UNSIGNED_SHORT_5_5_5_1",
            "GL_UNSIGNED_INT_8_8_8_8",
            "GL_UNSIGNED_INT_10_10_10_2",
            "GL_UNSIGNED_BYTE_2_3_3_REV",
            "GL_UNSIGNED_SHORT_5_6_5",
            "GL_UNSIGNED_SHORT_5_6_5_REV",
            "GL_UNSIGNED_SHORT_4_4_4_4_REV",
            "GL_UNSIGNED_SHORT_1_5_5_5_REV",
            "GL_UNSIGNED_INT_8_8_8_8_REV",
            "GL_UNSIGNED_INT_2_10_10_10_REV",
        ]
        
        private function pixelTypeToString(type:uint):String
        {
            if (type == GL_BITMAP)
                return PIXEL_TYPE[type - GL_BITMAP]
            else if (type <= GL_FLOAT)
                return PIXEL_TYPE[type - GL_BYTE]
            else if (type <= GL_BGRA)
                return PIXEL_TYPE[type - GL_BGR]
            else
                return PIXEL_TYPE[type - GL_UNSIGNED_BYTE_3_3_2]
        }
        
        
        private function convertPixelDataToBGRA(width:int, height:int, srcFormat:uint, src:ByteArray, srcOffset:uint):ByteArray
        {
            //var srcBytesPerPixel:int
            var pixelCount:int = width * height
            var dst:ByteArray = new ByteArray()
            dst.length = pixelCount * 4 // BGRA is 4 bytes
            
            var originalPosition:uint = src.position
            src.position = srcOffset
            
            var b:int = 0
            var g:int = 0
            var r:int = 0
            var a:int = 0xFF // fully opaque by default (for conversions from formats that don't have alpha)
            //var a:int = 100 // transparent for debugging

            for (var i:int = 0; i < pixelCount; i++)
            {
                switch (srcFormat)
                {
                    case GL_RGBA:
                        r = src.readByte()
                        g = src.readByte()
                        b = src.readByte()
                        a = src.readByte()
                    break
                    
                    case GL_RGB:
                        r = src.readByte()
                        g = src.readByte()
                        b = src.readByte()
                    break

                    default:
                        if (log) log.send("[Warning] Unsupported texture format: " + PIXEL_FORMAT[srcFormat - GL_COLOR_INDEX])
                        return dst
                }
                
                // BGRA
                dst.writeByte(b)
                dst.writeByte(g)
                dst.writeByte(r)
                dst.writeByte(a)
            }

            // restore the position so the function doesn't have side-effects
            src.position = originalPosition
            return dst
        }


        public function glTexSubImage2D(target:uint, level:int, xoff:int, yoff:int, width:int, height:int, format:uint, imgType:uint, ptr:uint, ram:ByteArray):void
        {
            
            if (log) log.send( "glTexSubImage2D " + target + " l:" + level + " " + xoff + " " + yoff + " " + width + "x" + height +  
                      PIXEL_FORMAT[format - GL_COLOR_INDEX] + " " + pixelTypeToString(imgType) + " " + ptr.toString(16) + "\n")

            if(activeTexture && activeTexture.texture) {
                activeTexture.texture.dispose()
                textures[textureSamplerIDs[activeTextureUnit]] = null
                glBindTexture(target, textureSamplerIDs[activeTextureUnit])
            }

            glTexImage2D(target, level, format, width, height, 0, format, imgType, ptr, ram)
        }

        public function glTexImage2D(target:uint, level:int, intFormat:int, width:int, height:int, border:int, format:uint, imgType:uint, ptr:uint, ram:ByteArray):void
        {
            
            if (log) log.send( "[IMPLEMENTED] glTexImage2D " + target + " texid: " + textureSamplerIDs[activeTextureUnit] + " l:" + level + " " + intFormat + " " + width + "x" + height + " b:" + border + " " + 
                      PIXEL_FORMAT[format - GL_COLOR_INDEX] + " " + pixelTypeToString(imgType) + " " + imgType.toString(16) + "\n")


            if (intFormat == GL_LUMINANCE)
            {
                // Unsupported. TODO - Squelch all PF_G8 textures.
                width = width/2
                height = height/2
            }
            
            if (width == 0 || height == 0) 
                return
            
            // Context3D only supports BGRA and COMPRESSED formats
            var data:ByteArray
            var dataOffset:uint
            if (format != GL_BGRA)
            {
                // Convert the texture format
                data = convertPixelDataToBGRA(width, height, format, ram, ptr)
                dataOffset = 0
            }
            else
            {
                data = ram
                dataOffset = ptr
            }

            // Create appropriate texture type and upload data.
            if (target == GL_TEXTURE_2D)
            {
                create2DTexture(width, height, level, data, dataOffset)
            }
            else if (target >= GL_TEXTURE_CUBE_MAP_POSITIVE_X && target <= GL_TEXTURE_CUBE_MAP_NEGATIVE_Z)
            {
                createCubeTexture(width, target, level, data, dataOffset)
            }
            else 
            {
                if (log) log.send( "[NOTE] Unsupported texture type " + target + " for glCompressedTexImage2D")
            }
        }
        
        public function glCompressedTexImage2D(target:uint, level:int, intFormat:uint, width:int, height:int, border:int, imageSize:int, ptr:uint, ram:ByteArray):void
        {
            // if (log) log.send( "[IMPLEMENTED] glCompressedTexImage2D " + target + " " + level + " " + intFormat + " " + width + " " + height + " " + border + " " + imageSize + "\n")

            //trace("intFormat is " + intFormat)
            
            // Create appropriate texture type and upload data.
            if (target == GL_TEXTURE_2D)
                create2DTexture(width, height, level, ram, ptr, (intFormat == 2 || intFormat == 3), true)
            else if (target >= GL_TEXTURE_CUBE_MAP_POSITIVE_X && target <= GL_TEXTURE_CUBE_MAP_NEGATIVE_Z)
                createCubeTexture(width, target, level, ram, ptr, (intFormat == 2 || intFormat == 3), true)
            else {
                if (log) log.send( "[NOTE] Unsupported texture type " + target + " for glCompressedTexImage2D")
            }
        }
        
        private static var texID:uint = 1 // so we have 0 as non-valid id
        // texID == # of textures + 1

        // Returns index of first texture, guaranteed to be contiguous
        public function glGenTextures(length:uint):uint
        {
            var result:uint = texID
            if (log) log.send( "[IMPLEMENTED] glGenTextures " + length + ", returning ID = [ " + result + ", " + (result + length - 1) + " ]\n")
            for (var i:int = 0; i < length; i++) {
                textures[texID] = new TextureInstance()
                textures[texID].texID = texID
                texID++
            }
            return result
        }

        public function glDeleteTexture(texid:uint)
        {
            if(textures[texid] == null) {
                if (log) log.send( "[WARNING] glDeleteTexture called on non-existant texture " + texid + "\n")
                return
            }

            if (log) log.send( "glDeleteTexture called for " + texid + "\n")

            if(textures[texid].texture)
                textures[texid].texture.dispose()

            if(textures[texid].cubeTexture)
                textures[texid].cubeTexture.dispose()

            textures[texid] = null // TODO: fix things so we can eventually reuse textureIDs
        }
        
        public function glPixelStorei(pname:uint, param:int):void
        {
            // if (log) log.send( "[STUBBED] glPixelStorei " + pname + " " + param + "\n")
        }

        private static var bufferID:uint = 0

        // Returns index of first buffer, guaranteed to be contiguous
        public function glGenBuffers(length:int):uint
        {
            // if (log) log.send( "[IMPLEMENTED] glGenBuffers " + length + "\n")
            //ram.position = ptr
            var result:uint = bufferID + 1
            for (var i:int = 0; i < length; i++) {
                dataBuffers[++bufferID] = new DataBuffer()
                dataBuffers[bufferID].id = bufferID
                //ram.writeUnsignedInt(bufferID)
            }
            return bufferID
        }
        
        private static var fbID:uint = 0

        // Returns index of first buffer, guaranteed to be contiguous
        public function glGenFrameBuffers(length:int):uint
        {
            // trace( "glGenFramebuffers " + length + "\n")
            //ram.position = ptr
            var result:uint = fbID + 1
            for (var i:int = 0; i < length; i++) {
                frameBuffers[++fbID] = new FrameBuffer()
                //ram.writeUnsignedInt(fbID)
                // trace( "glGenFramebuffers: " + fbID + "\n")
            }
            return result
        }

        private static var rbID:uint = 0
        
        // Returns index of first buffer, guaranteed to be contiguous
        public function glGenRenderBuffers(length:int):uint
        {
            // trace( "glGenRenderBuffers " + length + "\n")
            //ram.position = ptr
            var result:uint = rbID + 1
            for (var i:int = 0; i < length; i++) {
                renderBuffers[++rbID] = new RenderBuffer()
                //ram.writeUnsignedInt(rbID)
                // trace( "glGenRenderBuffers: " + rbID + "\n")
            }
            return result
        }

        public function glRenderbufferStorage(target:uint, format:uint, width:int, height:int):void
        {
            // trace("glRenderbufferStorage " + target + " " + format + " " + width + " " + height + "\n")

            // HACK: check the format and determine whether we should actually allocate storage.
            // For depth formats, we don't need to, since we always have to use the default
            // depth surface.
        }

        public function glBindBuffer(target:uint,id:uint):void
        {
            if (target == GL_ARRAY_BUFFER)
            {
                activeArrayBuffer = dataBuffers[id]
                if (activeArrayBuffer) activeArrayBuffer.target = target
                // if (log) log.send( "[IMPLEMENTED] glBindBuffer GL_ARRAY_BUFFER " + id + " id: " + (activeArrayBuffer ? activeArrayBuffer.id : "null") + "\n")
            }
            else if (target == GL_ELEMENT_ARRAY_BUFFER)
            {
                activeElementBuffer = dataBuffers[id]
                if (activeElementBuffer) activeElementBuffer.target = target
                // if (log) log.send( "[IMPLEMENTED] glBindBuffer GL_ELEMENT_ARRAY_BUFFER " + id + " id: " + (activeElementBuffer ? activeElementBuffer.id : "null") + "\n")
            }
            //else
                // if (log) log.send( "[NOTE] unsupported target format for glBindBuffer." )
        }
        
        public function validateFramebufferState(validateShouldClearIfNeeded:Boolean):void
        {
            // trace("validateFramebufferState called")
            if (pendingFrameBuffer != activeFrameBuffer)
            {
                if (pendingFrameBuffer == null)
                {
                    // trace("validateFramebufferState target is the backbuffer")
                    activeFrameBuffer = null
                    context.setRenderToBackBuffer()
                }
                else
                {
                    if (pendingFrameBuffer.colorTexture != null)
                    {
                        // trace("validateFramebufferState target is an offscreen texture, activating")
                        activeFrameBuffer = pendingFrameBuffer
                        context.setRenderToTexture(activeFrameBuffer.colorTexture, activeFrameBuffer.enableDepthAndStencil)

                        // trace("validateFramebufferState: validateShouldClearIfNeeded is " + validateShouldClearIfNeeded)
                        // trace("validateFramebufferState: activeFrameBuffer.lastClearFramestamp is " + activeFrameBuffer.lastClearFramestamp)
                        // trace("validateFramebufferState:                            framestamp is " + framestamp)
                        if (validateShouldClearIfNeeded)// && activeFrameBuffer.lastClearFramestamp != framestamp)
                        {
                            // trace("validateFramebufferState target cleared")
                            context.clear(0.0, 0.0, 0.0, 0.0)
                            activeFrameBuffer.lastClearFramestamp = framestamp
                        }
                    }
                    else
                    {
                        // trace("validateFramebufferState target is an offscreen texture, but the texture doesn't exist yet\n")
                    }
                }
            }
        }

        public function glBindFramebuffer(target:uint,framebuffer:uint):void
        {
            // trace("glBindFramebuffer " + target + " " + framebuffer)

            var newPendingFrameBuffer:FrameBuffer = frameBuffers[framebuffer]
            if (newPendingFrameBuffer != pendingFrameBuffer)
            {
                // If we're changing framebuffers and the current one never became active,
                // we might need to clear it so that we can use it as a texture
                if (pendingFrameBuffer != activeFrameBuffer)
                {
                    // Be sure to only do this if we actually have a texture attached and we haven't
                    // already cleared the buffer this frame
                    if (pendingFrameBuffer != null && pendingFrameBuffer.colorTexture != null)// &&
                        //pendingFrameBuffer.lastClearFramestamp != framestamp)
                    {
                        // trace("glBindFramebuffer call is clearing the never-activated pendingFrameBuffer before unbinding")
                        context.setRenderToTexture(pendingFrameBuffer.colorTexture, false)
                        context.clear(0.0, 0.0, 0.0, 0.0)
                        pendingFrameBuffer.lastClearFramestamp = framestamp

                        // Restore the active framebuffer
                        if (activeFrameBuffer != null && activeFrameBuffer.colorTexture != null)
                        {
                            context.setRenderToTexture(activeFrameBuffer.colorTexture, activeFrameBuffer.enableDepthAndStencil)
                        }
                    }
                }
                // Finally, set the new pending framebuffer
                // trace("glBindFramebuffer call has updated the pendingFrameBuffer")
                pendingFrameBuffer = newPendingFrameBuffer
            }
            else
            {
                // trace("glBindFramebuffer call is redundant, avoided")
            }
        }
        
        public function glFramebufferRenderbuffer(target:uint,attachment:uint,renderbuffertarget:uint,renderbuffer:uint):void
        {
            // trace("glFramebufferRenderbuffer " + target + " " + attachment + " " + renderbuffertarget + " " + renderbuffer + "\n")
            
            // HACK
            if (pendingFrameBuffer != null)
            {
                // trace("glFramebufferRenderbuffer is setting enableDepthAndStencil to true")
                pendingFrameBuffer.enableDepthAndStencil = true
            }
        }

        public function glFramebufferTexture2D(target:uint,attachment:uint,textarget:uint,texture:uint,level:int):void
        {
            // trace("glFramebufferTexture2D " + target + " " + attachment + " " + textarget + " " + texture + " " + level + "\n")

            if (pendingFrameBuffer != null)
            {
                // trace("glFramebufferTexture2D is updating the color texture on pendingFrameBuffer")
                pendingFrameBuffer.colorTexture = textures[texture].texture
            }
        }

        public function glBindRenderbuffer(target:uint,renderbuffer:uint):void
        {
            // trace("glBindRenderbuffer " + target + " " + renderbuffer + "\n")
            activeRenderBuffer = renderBuffers[renderbuffer]
        }
        
        public function glBufferData(target:uint, usage:uint, data:ByteArray):void
        {
            if (usage != GL_STREAM_DRAW && usage != GL_STATIC_DRAW) {
                // if (log) log.send( "[NOTE] unsupported usage format for glBufferData." )
            } else {
                if (target == GL_ARRAY_BUFFER)
                {
                    // if (log) log.send( "[IMPLEMENTED] glBufferData GL_ARRAY_BUFFER (id: " + activeArrayBuffer.id +  " ) " + data.length + " " + usage + "\n")
                    activeArrayBuffer.usage = usage
                    activeArrayBuffer.data = data
                    activeArrayBuffer.size = data.length
                }
                else if (target == GL_ELEMENT_ARRAY_BUFFER)
                {
                    // if (log) log.send( "[IMPLEMENTED] glBufferData GL_ELEMENT_ARRAY_BUFFER (id: " + activeElementBuffer.id +  " ) " + data.length + " " + usage + "\n")
                    activeElementBuffer.usage = usage
                    activeElementBuffer.data = data
                    activeElementBuffer.size = data.length
                }
                else
                    if (log) log.send( "[NOTE] unsupported target format for glBufferData." )
            }
        }
        
//        public function glDepthMask(flag:Boolean):void
//        {
//            // if (log) log.send( "[IMPLEMENTED] glDepthMask " + flag + "\n")
//            contextDepthMask = flag 
//        }
        
        public function glColorMask(red:Boolean, green:Boolean, blue:Boolean, alpha:Boolean):void
        {
            if (log) log.send( "[IMPLEMENTED] glColorMask " + red + " " + green + " " + blue + " " + alpha + "\n")
            context.setColorMask(red, green, blue, alpha)  
        }
        
        
        /* StencilOp */
        //public static const GL_ZERO:uint =        0
        public static const GL_KEEP:uint =        0x1E00
        public static const GL_REPLACE:uint =     0x1E01
        public static const GL_INCR:uint =        0x1E02
        public static const GL_DECR:uint =        0x1E03
        public static const GL_INVERT:uint =      0x150A
        public static const GL_INCR_WRAP:uint =   0x8507
        public static const GL_DECR_WRAP:uint =   0x8508
        
        
        private function stencilOpToContext3DStencilAction(op:uint):String
        {
            switch (op)
            {
                case GL_ZERO: return Context3DStencilAction.ZERO
                case GL_KEEP: return Context3DStencilAction.KEEP
                case GL_REPLACE: return Context3DStencilAction.SET
                case GL_INCR: return Context3DStencilAction.INCREMENT_SATURATE
                case GL_DECR: return Context3DStencilAction.DECREMENT_SATURATE
                case GL_INVERT: return Context3DStencilAction.INVERT
                case GL_INCR_WRAP: return Context3DStencilAction.INCREMENT_WRAP
                case GL_DECR_WRAP: return Context3DStencilAction.DECREMENT_WRAP
                default:
                    if (log) log.send("[Warning] Unknown stencil op: 0x" + op.toString(16))
                    return null
            }
        }
        
        private function commitStencilState():void
        {
            if (contextEnableStencil)
            {
                var triangleFace:String = contextEnableCulling ? glCullModeToContext3DTriangleFace(glCullMode, !frontFaceClockWise) : Context3DTriangleFace.FRONT_AND_BACK
                context.setStencilActions(triangleFace, 
                    contextStencilCompareMode, 
                    contextStencilActionPass, 
                    contextStencilActionDepthFail, 
                    contextStencilActionStencilFail)
            }
            else
            {
                // Reset to default
                context.setStencilActions(Context3DTriangleFace.FRONT_AND_BACK, 
                    Context3DCompareMode.ALWAYS, 
                    Context3DStencilAction.KEEP, 
                    Context3DStencilAction.KEEP, 
                    Context3DStencilAction.KEEP)
            }
        }
        
        public function glStencilOp(fail:uint, zfail:uint, zpass:uint):void
        {
            if (log) log.send("glStencilOp")
            contextStencilActionStencilFail = stencilOpToContext3DStencilAction(fail)
            contextStencilActionDepthFail = stencilOpToContext3DStencilAction(zfail)
            contextStencilActionPass = stencilOpToContext3DStencilAction(zpass)
            commitStencilState()
        }
        
        //extern void glStencilFunc (GLenum func, GLint ref, GLuint mask):void
        public function glStencilFunc(func:uint, ref:int, mask:uint):void
        {
            if (log) log.send("glStencilFunc")
            contextStencilCompareMode = convertCompareMode(func)
            context.setStencilReferenceValue(ref, mask, mask)
            commitStencilState()
        }

        
//        public function glDepthFunc(func:uint):void
//        {
//            //trace( "[IMPLEMENTED] glDepthFunc " + func + "\n")       
//            if (func == GL_NEVER) contextDepthFunc = Context3DCompareMode.NEVER
//            else if (func == GL_LESS) contextDepthFunc = Context3DCompareMode.LESS
//            else if (func == GL_EQUAL) contextDepthFunc = Context3DCompareMode.EQUAL
//            else if (func == GL_LEQUAL) contextDepthFunc = Context3DCompareMode.LESS_EQUAL
//            else if (func == GL_GREATER) contextDepthFunc = Context3DCompareMode.GREATER
//            else if (func == GL_NOTEQUAL) contextDepthFunc = Context3DCompareMode.NOT_EQUAL
//            else if (func == GL_GEQUAL) contextDepthFunc = Context3DCompareMode.GREATER_EQUAL
//            else if (func == GL_ALWAYS) contextDepthFunc = Context3DCompareMode.ALWAYS
//        }

        var scissorRect:Rectangle
        var contextEnableScissor:Boolean = false
        
        public function glScissor(x:int, y:int, width:int, height:int):void
        {
            if(log) log.send("glScissor " + x + ", " + y + ", " + width + ", " + height)
            scissorRect = new Rectangle(x, y, x + width, y + height)
            if(contextEnableScissor)
                context.setScissorRectangle(scissorRect)
        }

        public function glViewport(x:int, y:int, width:int, height:int):void
        {
            // Not natively supported on this platform. Emulate with a scissor and VS scale/bias.
        }

        public function glDepthRangef(near:Number, far:Number):void
        {
            // if (log) log.send( "[STUBBED] glDepthRangef " + near + " " + far + "\n")         
        }

        public function glClearDepth(depth:Number):void
        {
            // if (log) log.send( "[IMPLEMENTED] glClearDepthf " + depth + "\n")   
            contextClearDepth = depth          
        }

//        public function glFrontFace(mode:uint):void
//        {
//            // if (log) log.send( "[IMPLEMENTED] glFrontFace " + mode + "\n")
//            contextFrontFace = mode            
//        }

        public function glClearStencil(s:int):void
        {
            // if (log) log.send( "[IMPLEMENTED] glClearStencil " + s + "\n")
            contextClearStencil = s                
        }

        public function glEnableVertexAttribArray(index:uint):void
        {
            // if (log) log.send( "[IMPLEMENTED] glEnableVertexAttribArray " + index + "," + vertexBufferAttributes[index] + "\n")
            if (!activeArrayBuffer)
                return

            vertexAttributesDirty = true
            vertexBufferAttributes[index].enabled = true
        }

        public function glDisableVertexAttribArray(index:uint):void
        {
            // if (log) log.send( "[IMPLEMENTED] glDisableVertexAttribArray " + index + "\n")
            if (!activeArrayBuffer)
                return

            vertexAttributesDirty = true
            vertexBufferAttributes[index].enabled = false       
        }

/*        public function glUniform1i(location:int, v0:int):void
        {
            if (location < 0) return
            
            var uniformName:String = activeProgram.uniformNames[location]

            // Track our samplers.
            var programVar:AGALVar = activeProgram.fragmentShaderVars[uniformName]
            if (programVar && programVar.isSampler)
                activeProgram.activeSamplers[v0] = true

            setProgramConstantData(location, CDATA_FLOAT1, v0, activeProgram)
        }
  */     
        public function glDrawElements(mode:uint, count:int, type:uint, ptr:uint, ptrlen:uint, ram:ByteArray):void
        {
            // if (log) log.send( "glDrawElements " + mode + " " + count + " " + type + " " + data.length + "\n")

            // Only support 'sequential' triangle strips in DE right now.
            if (mode == 5)
            {
// This will enable beam hack for rendering
/**/
                activeElementBuffer = acquireSequentialTriStripIndexBuffer(count)
                // Adjust the count
                var triCount:int = (count - 2)
                type = indexBufferSequentialTriStrip.indicesSize
                count = triCount * 3
                mode = 4
                ptr = 0
                ptrlen = count * 2
/**/
//                return
            }

            var dataBuffer:DataBuffer = activeElementBuffer
            var pos:uint = 0

            if (!activeElementBuffer)
            {
                dataBuffer = acquireBufferFromPool(count, 0, GL_ELEMENT_ARRAY_BUFFER)
                dataBuffer.indicesSize = type
                dataBuffer.target = GL_ELEMENT_ARRAY_BUFFER
                dataBuffer.data.position = 0
                dataBuffer.data.writeBytes(ram, ptr, ptrlen)
                dataBuffer.data.length = ptrlen
                dataBuffer.data.position = 0
                dataBuffer.size = ptrlen
                uploadBuffer(dataBuffer)
            }
            else
            {
                pos = ptr/2
            }
            
            // Construct our associated Context3D's index buffer if necessary.
            if (dataBuffer && !dataBuffer.uploaded)
            {
                dataBuffer.indicesSize = type
                uploadBuffer(dataBuffer)
            }
         
            // Textures
            var ti:TextureInstance
            for (var i:int = 0; i < 1; i++ )
            {
                if (activeProgram.activeSamplers[i])
                {
                    ti = textureSamplers[i]
                    context.setTextureAt(i, ti.boundType == GL_TEXTURE_2D ? ti.texture : ti.cubeTexture)
                    if(log) log.send("setTexture " + i + " -> " + ti.texID)
                }
                else
                {
                    context.setTextureAt(i, null)
                    if(log) log.send("setTexture " + i + " -> 0")
            }
            }

            activeProgram.updateConstants(context)
            

            // Attributes
            if (vertexAttributesDirty)
            {
        var len:uint = vertexBufferAttributes.length
                for (var v:int = 0; v < len ; v++)
                {
                    var vba:VertexBufferAttribute = vertexBufferAttributes[v]
                    if (vba && vba.enabled && activeProgram.vertexStreamIndicies[v])
                    {  
                        var format:String
                        if (vba.size == 3 && vba.type == GL_FLOAT)
                            format = Context3DVertexBufferFormat.FLOAT_3
                        else if (vba.size == 2 && vba.type == GL_FLOAT)
                            format = Context3DVertexBufferFormat.FLOAT_2
                        else if (vba.size == 4 && vba.type == GL_UNSIGNED_BYTE)
                            format = Context3DVertexBufferFormat.BYTES_4
                        else if (vba.size == 4 && vba.type == GL_FLOAT)
                            format = Context3DVertexBufferFormat.FLOAT_4
                        else if (vba.size == 1 && vba.type == GL_FLOAT)
                            format = Context3DVertexBufferFormat.FLOAT_1
                        else
                            throw(new Error("Unhandled vertex buffer format size " + vba.size + " type " + vba.type))

                        context.setVertexBufferAt(v, vba.buffer.vertexBuffer, vba.offset / 4, format)
                    }
                    else
                    {
                        context.setVertexBufferAt(v, null, 0, "")
                    }
                }
                        
                vertexAttributesDirty = false
            }

            // trace("validateFramebufferState from glDrawElements")
            validateFramebufferState(true)

            if(contextEnableDepth)
                context.setDepthTest(contextDepthMask, contextDepthFunc)
            else
                context.setDepthTest(false, Context3DCompareMode.ALWAYS)

            //trace("Draw Triangles program " + activeProgram.id)
            context.drawTriangles(dataBuffer.indexBuffer, pos, count/3)
        }

        private var indexBufferCache:DataBuffer
        private var indexBufferQuadCache:ByteArray = new ByteArray()

        public function glDrawArrays(mode:uint, first:uint, count:uint):void
        {
            var buffer:DataBuffer
        var numTris:uint = count - 2
            if (count == 4 && mode == 5)
            {
                buffer = acquireBufferFromPool(count, 0, GL_ELEMENT_ARRAY_BUFFER)
                buffer.indexBuffer = context.createIndexBuffer(6)
                buffer.indexBuffer.uploadFromByteArray(indexBufferQuadCache, 0, 0, 6)
                buffer.uploaded = true
            }
            else
            {
                if (mode == 5) // TODO: Add proper support for arbitrary TS index buffer.
                    return
                buffer = indexBufferCache
            }
            
            // Textures
            for (var i:int = 0; i < 1; i++ )
            {
                var ti:TextureInstance = textureSamplers[i]
                if (activeProgram.activeSamplers[i] && ti)
                {
                    context.setTextureAt(i, ti.boundType == GL_TEXTURE_2D ? ti.texture : ti.cubeTexture)
                    if(log) log.send("setTexture " + i + " -> " + ti.texID)
                }
                else
                {
                    context.setTextureAt(i, null)
                    if(log) log.send("setTexture " + i + " -> 0")
            }
            }
            
            activeProgram.updateConstants(context)

            // Attributes
            if (vertexAttributesDirty)
            {
        var len:uint = vertexBufferAttributes.length
                for (var v:int = 0; v < len; v++)
                {
                    var vba:VertexBufferAttribute = vertexBufferAttributes[v]
                    if (vba && vba.enabled && activeProgram.vertexStreamIndicies[v])
                    {  
                        var format:String
                        if (vba.size == 3 && vba.type == GL_FLOAT)
                            format = Context3DVertexBufferFormat.FLOAT_3
                        else if (vba.size == 2 && vba.type == GL_FLOAT)
                            format = Context3DVertexBufferFormat.FLOAT_2
                        else if (vba.size == 4 && vba.type == GL_UNSIGNED_BYTE)
                            format = Context3DVertexBufferFormat.BYTES_4
                        else if (vba.size == 4 && vba.type == GL_FLOAT)
                            format = Context3DVertexBufferFormat.FLOAT_4
                        else if (vba.size == 1 && vba.type == GL_FLOAT)
                            format = Context3DVertexBufferFormat.FLOAT_1
                        else
                            throw(new Error("Unhandled vertex buffer format size " + vba.size + " type " + vba.type))
                            
                        context.setVertexBufferAt(v, vba.buffer.vertexBuffer, vba.offset / 4, format)
                    }
                    else
                    {
                        context.setVertexBufferAt(v, null, 0, "")
                    }
                }
                        
                vertexAttributesDirty = false
            }

            // trace("validateFramebufferState from glDrawArrays")
            validateFramebufferState(true)

            if(contextEnableDepth)
                context.setDepthTest(contextDepthMask, contextDepthFunc)
            else
                context.setDepthTest(false, Context3DCompareMode.ALWAYS)

            //trace("DrawArrays program " + activeProgram.id )
            context.drawTriangles(buffer.indexBuffer, 0, numTris)
        }
        
        public function glVertexAttribPointer(index:uint, size:int, type:uint, normalized:Boolean, stride:int, ptr:uint, ptrlen:uint, ram:ByteArray):void
        {
            // if (log) log.send( "glVertexAttribPointer " + index + " " + size + " " + type + " " + normalized + " " + stride + " " + offset + "\n")
            var isGeneric:Boolean = true
            var dataBuffer:DataBuffer = activeArrayBuffer
            if (!dataBuffer)
            {
                isGeneric = false
                dataBuffer = acquireBufferFromPool(ptrlen / stride, stride / 4,  GL_ARRAY_BUFFER)
        dataBuffer.data.position = 0
        dataBuffer.data.writeBytes(ram, ptr, ptrlen)
        dataBuffer.data.length = ptrlen
        dataBuffer.data.position = 0
                dataBuffer.size = ptrlen
            } else {
                var offset:uint = ptr
            }
                
            // Construct our associated Context3D's vertex buffer if necessary (now that we know stride).
            if (dataBuffer && !dataBuffer.uploaded)
            {
                dataBuffer.stride = stride
                uploadBuffer(dataBuffer)
            }

            var enabled:Boolean = vertexBufferAttributes[index] ? vertexBufferAttributes[index].enabled : false
            var vba:VertexBufferAttribute = new VertexBufferAttribute()
            vba.buffer = dataBuffer
            vba.offset = offset
            vba.stride = stride
            vba.size = size
            vba.type = type
            vba.normalize = normalized
            vba.isGeneric = isGeneric
            vba.enabled = enabled || !isGeneric 
            vertexBufferAttributes[index] = vba
            vertexAttributesDirty = true
        }
        
        public function glUseProgram(program:uint):void
        {
            // if (log) log.send( "[TODO] glUseProgram " + program + "\n")
            var pi:ProgramInstance = programs[program]
            if (pi)
            {
                // Check to see if the program has any constants and if not,
                // force an update anyway to ensure "automatic" ones are
                // valid
                pi.vertexConstantsDirty = true
                pi.fragmentConstantsDirty = true

                context.setProgram(pi.program)
            }
            else
            {
                context.setProgram(null)
            }

            activeProgram = program ? programs[program] : null
        }
        
/*        public function glLinkProgram(program:uint):void
        {
            // if (log) log.send( "[IMPLEMENTED] glLinkProgram " + program + "\n")
            var pi:ProgramInstance = programs[program]
            
            if (!macroAssembler)
                macroAssembler = new AGALMacroAssembler()
                
            // Assemble Vertex Shader
            var vertexShaderBytes:ByteArray = macroAssembler.assemble(Context3DProgramType.VERTEX, pi.vertexShader.source)
            pi.vertexShaderVars = macroAssembler.inputVars
            setCommonShaderConstants(pi, pi.vertexShaderVars, true)
            if (dumpShaderCode == true)
            {
                trace("VERTEX SHADER FOR PROGRAM " + program)
                trace(macroAssembler.asmCode)
            }

            //cache vertex stream positions
            for (var key:String in pi.vertexShaderVars)
            {
                var agalVar:AGALVar = pi.vertexShaderVars[key]
                if (agalVar.isVertexAttribute)
                {
                        pi.vertexStreamIndicies[agalVar.StreamPosition] = true
                }
            }

            
            // Assemble Fragment Shader
            var vertexVaryings:Dictionary = macroAssembler.varyings
            var fragmentShaderBytes:ByteArray = macroAssembler.assemble(Context3DProgramType.FRAGMENT, pi.fragmentShader.source, vertexVaryings)
            pi.fragmentShaderVars = macroAssembler.inputVars
            setCommonShaderConstants(pi, pi.fragmentShaderVars, false)
            if (dumpShaderCode == true)
            {
                trace("FRAGMENT SHADER FOR PROGRAM " + program)
                trace(macroAssembler.asmCode)
            }
            
            // Upload
            pi.program.upload(vertexShaderBytes, fragmentShaderBytes)
        }
*/
        
        public function glShaderSource(shader:uint, str:String):void
        {
            if (dumpShaderCode == true)
            {
                // if (log) log.send( str + "\n" )
                trace(str)
            }
            var si:ShaderInstance = shaders[shader]
            si.source = str
        }
        
        public function glAttachShader(program:uint, shader:uint):void
        {
            // if (log) log.send( "[IMPLEMENTED] glAttachShader " + program + " " + shader + "\n")
            var pi:ProgramInstance = programs[program]
            var si:ShaderInstance = shaders[shader]
            if (si.shaderType == GL_VERTEX_SHADER)
                pi.vertexShader = si
            else 
                pi.fragmentShader = si
        }

        private static var progID:uint = 0

        public function glCreateProgram():uint
        {
            progID++
            // if (log) log.send( "[IMPLEMENTED] glCreateProgram " + progID + "\n")
            var pi:ProgramInstance = new ProgramInstance()
            programs[progID] = pi
            pi.id = progID
            pi.program = context.createProgram()
            return progID
        }

        private static var shaderID:uint = 0

        public function glCreateShader(shaderType:uint):uint
        {
            shaderID++
            var si:ShaderInstance = new ShaderInstance()
            shaders[shaderID] = si
            si.shaderType = shaderType
            return shaderID
        }
        
//        public function glGetAttribLocation(program:uint, name:String):int
//        {
//            var p:ProgramInstance = programs[program]
//            var location:int = getVarLocation(name, p)
//
//            if (location != -1)
//            {
//                programs[program].attributePositions[name] = location
//                programs[program].attributeNames[location] = name
//            }
//            return location
//        }
        
//        public function glGetUniformLocation(program:uint, name:String):int
//        {
//            var p:ProgramInstance = programs[program]
//            var location:int = getVarLocation(name, p)
//            
//            // if (log) log.send( "[IMPLEMENTED] glGetUniformLocation " + program + " " + name + " " + location + "\n")
//            if (location != -1)
//            {
//                programs[program].uniformPositions[name] = location
//                programs[program].uniformNames[location] = name
//            }
//            return location
//        }
        
        public function glBlendEquationSeparate(modeRGB:uint, modeAlpha:uint):void
        {
            // TODO
            //trace("glBlendEquationSeparate: modeRGB = " + modeRGB + ", modeA = " + modeAlpha)
        }
        
        private function translateBlendFactor( openGLBlendFactor:uint ): String
        {
            if ( openGLBlendFactor == GL_ONE )
            {
                return Context3DBlendFactor.ONE
            }
            else if ( openGLBlendFactor == GL_ZERO )
            {
                return Context3DBlendFactor.ZERO
            }
            else if ( openGLBlendFactor == GL_SRC_ALPHA )
            {
                return Context3DBlendFactor.SOURCE_ALPHA
            }
            else if ( openGLBlendFactor == GL_ONE_MINUS_SRC_ALPHA )
            {
                return Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA
            }
            else if ( openGLBlendFactor == GL_DST_ALPHA )
            {
                return Context3DBlendFactor.DESTINATION_ALPHA
            }
            else if ( openGLBlendFactor == GL_ONE_MINUS_DST_ALPHA )
            {
                return Context3DBlendFactor.ONE_MINUS_DESTINATION_ALPHA
            }
            else if ( openGLBlendFactor == GL_SRC_COLOR )
            {
                return Context3DBlendFactor.SOURCE_COLOR
            }
            else if ( openGLBlendFactor == GL_ONE_MINUS_SRC_COLOR )
            {
                return Context3DBlendFactor.ONE_MINUS_SOURCE_COLOR
            }
            else if ( openGLBlendFactor == GL_DST_COLOR )
            {
                return Context3DBlendFactor.DESTINATION_COLOR
            }
            else if ( openGLBlendFactor == GL_ONE_MINUS_DST_COLOR )
            {
                return Context3DBlendFactor.ONE_MINUS_DESTINATION_COLOR
            }
            return Context3DBlendFactor.ONE
        }
        
        public function glBlendFunc(sourceFactor:uint, destinationFactor:uint):void
        {
            contextSrcBlendFunc = translateBlendFactor(sourceFactor)
            contextDstBlendFunc = translateBlendFactor(destinationFactor)

            if (log) log.send("glBlendFunc " + contextSrcBlendFunc + ", " + contextDstBlendFunc)
            
            if (contextEnableBlending && !disableBlending)
                context.setBlendFactors(contextSrcBlendFunc, contextDstBlendFunc)
        }

        public function glBlendFuncSeparate(srcRGB:uint, dstRGB:uint,srcAlpha:uint, dstAlpha:uint):void
        {
            contextSrcBlendFunc = translateBlendFactor( srcRGB )
            contextDstBlendFunc = translateBlendFactor( dstRGB )

            if(srcRGB == GL_ONE && dstRGB == GL_ONE && srcAlpha == GL_ZERO && dstAlpha == GL_ONE) 
            {
            }
            else if(srcRGB == GL_SRC_ALPHA && dstRGB == GL_ONE && srcAlpha == GL_ZERO && dstAlpha == GL_ONE) 
            {
            }
            else if(srcRGB == GL_SRC_ALPHA && dstRGB == GL_ONE_MINUS_SRC_ALPHA && srcAlpha == GL_ZERO && dstAlpha == GL_ONE) 
            {
            }
            else if (srcRGB == GL_DST_COLOR && dstRGB == GL_ZERO && srcAlpha == GL_ZERO && dstAlpha == GL_ONE)
            {
            }
            else if (srcRGB == GL_DST_COLOR && dstRGB == GL_ZERO && srcAlpha == GL_ONE && dstAlpha == GL_ZERO)
            {
            }
            else if ( srcRGB != srcAlpha || dstRGB != dstAlpha )
            {
                if (log) log.send("glBlendFuncSeparate missing blend func: srcRGB = " + srcRGB + ", drtRGB = " + dstRGB + ", srcA = " + srcAlpha + ", dstA = " + dstAlpha)
            }
            
            if (contextEnableBlending && !disableBlending)
            {
                context.setBlendFactors(contextSrcBlendFunc, contextDstBlendFunc)
            }
//            else
//            {
//                trace("glBlendFuncSeparate: contextEnableBlending FALSE w/ srcRGB = " + srcRGB + ", drtRGB = " + dstRGB + ", srcA = " + srcAlpha + ", dstA = " + dstAlpha)
//            }
        }
        
        
        public function eglSwapBuffers():void
        {
            // trace( "eglSwapBuffers called")
            context.present()
            context.clear(0.0, 0.0, 0.0, 0.0)
            framestamp++

        //for(var s:String in counts) {
        //    trace("count " + s + ": " + counts[s])
        //    counts[s] = 0
        //}
        }
        
        // ======================================================================
        //  Functions
        // ----------------------------------------------------------------------
        protected function configureBackBuffer():void
        {
            context.configureBackBuffer(contextWidth, contextHeight, contextAA, true)
        }
        
        protected function create2DTexture(width:int, height:int, level:int, data:ByteArray, dataOff:uint, compressed:Boolean=false, compressedUpload:Boolean=false):void
        {
            var instance:TextureInstance = activeTexture
            if (!instance)
            {
                if (log) log.send( "[NOTE] No previously bound texture for glTexImage2D (2D)")
                return
            }

                if (!instance.texture)
                {
                    //trace("Compressed is " + compressed ? Context3DTextureFormat.COMPRESSED : Context3DTextureFormat.BGRA)
                    instance.texture = 
                        context.createTexture(width, height, compressed ? Context3DTextureFormat.COMPRESSED : Context3DTextureFormat.BGRA, dataOff == 0 ? true : false)
                    
                    textureSamplers[activeTextureUnit] = instance
                }

                if(level >= instance.mipLevels) {
                    instance.mipLevels++
                } else {
                    if (log) log.send( "[NOTE] glTexImage2D replacing mip...")
                }
                
            // FIXME (egeorgie) - we need a boolean param instead?
                //if (dataOff != 0)
                {
                    if (compressedUpload)
                        instance.texture.uploadCompressedTextureFromByteArray(data, dataOff)
                    else
                    {
//                    // Debug: generate texture image
//                        var bmp:BitmapData = new BitmapData(width, height, true, 0xFFFFFFFF)
//                        var shape:Shape = new Shape()
//                        
//                        for (var i:int = 0; i< width / 6; i++)
//                        {
//                            shape.graphics.lineStyle(2, (1 | (i << 16)))
//                            shape.graphics.drawCircle(width / 2, height / 2, width / 3 - i * 8 - 5)
//                        }
//                        bmp.draw(shape)
//                        var buf:ByteArray = bmp.getPixels(new Rectangle(0, 0, width, height))
//                        instance.texture.uploadFromByteArray(buf, 0, level)
                        
                        
//                    // Debug: display the texture image:
//                    //data.position = dataOff
//                        var bmp:BitmapData = new BitmapData(width, height)
//                        var buf:ByteArray = new ByteArray()
//                        var words:int = width * height
//                        buf.length = words * 4
//                        data.position = dataOff
//                        data.readBytes(buf, 0, buf.length)
//                        buf.position = 0
//                        bmp.setPixels(new Rectangle(0, 0, width, height), buf)
//                        debugTextures.push(bmp)
//
//                    
//                    var bmp:BitmapData = new BitmapData(width, height)
//                    var words:int = width * height
//                    data.position = dataOff
//                    bmp.setPixels(new Rectangle(0, 0, width, height), data)
//                    debugTextures.push(bmp)

                        instance.texture.uploadFromByteArray(data, dataOff, level)
                    }
                }
            }
        
        private var debugTextures:Vector.<BitmapData> = new Vector.<BitmapData>()
        private var debugTexQuadID:int = -1
        
        public function renderTextureGL():void
        {
            if (debugTexQuadID == -1)
            {
                debugTexQuadID = glGenLists(1)
                glNewList(debugTexQuadID, 0)
                glBegin(GL_QUADS)
                    glTexCoord(0, 0)
                    glColor(1, 0, 0, 1)
                    glVertex(0, 0, 0)
                
                    glTexCoord(1, 0)
                    glColor(1, 0, 0, 1)
                    glVertex(1, 0, 0)
    
                    glTexCoord(1, 1)
                    glColor(0, 0, 0, 1)
                    glVertex(1, 1, 0)
    
                    glTexCoord(0, 1)
                    glColor(0, 1, 0, 1)
                    glVertex(0, 1, 0)
                glEnd()
                glEndList()
            }
            
            var texPerRow:int = 20
            var w:Number = 2.0 / Number(texPerRow)
            var h:Number = w
            var x:Number = -1
            var y:Number = 1 - h
            
            var mStack:Vector.<Matrix3D> = modelViewStack
            var pStack:Vector.<Matrix3D> = projectionStack
            
            modelViewStack = new <Matrix3D>[ new Matrix3D()]
            projectionStack = new <Matrix3D>[ new Matrix3D()]
            
            glMatrixMode(GLAPI.GL_MODELVIEW)
            for (var i:int = 1; i < texID; i++)
            {
                glPushMatrix()
                glTranslate(x + Math.round(i % texPerRow) * w, y - Math.round(i / texPerRow) * h, 0)
                glScale(2 / texPerRow, 2 / texPerRow, 1)
                glBindTexture(GL_TEXTURE_2D, i)
                glCallList(debugTexQuadID)
                glPopMatrix()
            }
            
            modelViewStack = mStack
            projectionStack = pStack
            glMatrixMode(GLAPI.GL_MODELVIEW)
        }
        
        public function renderTextures(s:Sprite, width:int):void
        {
            var g:Graphics = s.graphics
            var count:int = debugTextures.length
            var x:int = 0
            var y:int = 0
            var w:int
            var h:int
            var rowHeight:int = 0
            for (var i:int; i < count; i++)
            {
                w = debugTextures[i].width
                h = debugTextures[i].height
                
                if (x + w > width)
                {
                    y += rowHeight
                    rowHeight = 0
                    x = 0
                }

                g.lineStyle(0, 0xFF0000)
                g.beginBitmapFill(debugTextures[i])
                g.drawRect(x, y, w, h)
                
                x += w
                rowHeight = Math.max(rowHeight, h)
            }
        }
        
        protected function createCubeTexture(width:int, target:uint, level:int, data:ByteArray, dataOff:uint, compressed:Boolean=false, compressedUpload:Boolean=false):void
        {
            var instance:TextureInstance = activeTexture
            if (instance)
            {
                if (!instance.cubeTexture)
                {
                    instance.cubeTexture = 
                        context.createCubeTexture(width, compressed ? Context3DTextureFormat.COMPRESSED : Context3DTextureFormat.BGRA, false)
                    
                    textureSamplers[activeTextureUnit] = instance
                }
                    
                var side:int = target - GL_TEXTURE_CUBE_MAP_POSITIVE_X
                
                if (compressedUpload)
                    instance.cubeTexture.uploadCompressedTextureFromByteArray(data, dataOff)
                else
                    instance.cubeTexture.uploadFromByteArray(data, dataOff, side, level)
            }
            else 
                if (log) log.send( "[NOTE] No previously bound texture for glCompressedTexImage2D (2D)")
        }
        
        protected function uploadBuffer(buffer:DataBuffer):void
        {
            if (buffer.target == GL_ARRAY_BUFFER)
            {
                if (!buffer.vertexBuffer)
                {
                    //trace("creating vertex buffer from context3D with args triangles " + buffer.size / buffer.stride + " stride " + buffer.stride / 4 )
                    buffer.vertexBuffer = context.createVertexBuffer(buffer.size / buffer.stride, buffer.stride / 4)
                }
                buffer.vertexBuffer.uploadFromByteArray(buffer.data, 0, 0, buffer.size / buffer.stride)
                buffer.uploaded = true
            }
            else if (buffer.target == GL_ELEMENT_ARRAY_BUFFER)
            {
                if (buffer.indicesSize == GL_UNSIGNED_SHORT)
                {
                    if (!buffer.indexBuffer)
                        buffer.indexBuffer = context.createIndexBuffer(buffer.size/2)
                    buffer.indexBuffer.uploadFromByteArray(buffer.data, 0, 0, buffer.size/2)
                    buffer.uploaded = true
                }
                else
                {
                    if (log) log.send( "[NOTE] Invalid index buffer format (not GL_UNSIGNED_SHORT)")
                }
            } else {
                if (log) log.send("INVALID BUFFER TARGET " + buffer.target)
            }
        }
        
        protected function setProgramConstantData(location:int, type:int, value:*, pi:ProgramInstance):void
        {
            var isFragment:Boolean = location >= 512
            location = isFragment ? location - 512 : location
            var buffer:Vector.<Number> = isFragment ? pi.fragmentConstantsData : pi.vertexConstantsData
            
        if(isFragment)
            pi.fragmentConstantsDirty = true
        else
            pi.vertexConstantsDirty = true            

            // Expand if necessary
            if (location + type >= buffer.length)
                buffer.length = Math.ceil((location + type + 1)/4)*4
            var vdata:Vector.<Number> = value as Vector.<Number>

            switch(type)
            {
                case CDATA_FLOAT1:
                    buffer[location] = value
                    break
                case CDATA_FLOAT2:
                    buffer[location] = vdata[0]
                    buffer[location+1] = vdata[1]
                    break
                case CDATA_FLOAT3:
                    buffer[location] = vdata[0]
                    buffer[location+1] = vdata[1]
                    buffer[location+2] = vdata[2]
                    break
                case CDATA_FLOAT4:
                    buffer[location] = vdata[0]
                    buffer[location+1] = vdata[1]
                    buffer[location+2] = vdata[2]
                    buffer[location+3] = vdata[3]
                    break
                case CDATA_MATRIX4x4:
                    for (var i:int = 0; i < 16; i++)
                        buffer[location+i] = vdata[i]
                    break
            }
        }
/*        
        protected function setCommonShaderConstants(pi:ProgramInstance, vars:Dictionary, isVertex:Boolean):void
        {
            for (var key:String in vars)
            {
                var agalVar:AGALVar = vars[key]
                if (agalVar.isConstant())
                {
                    var location:uint = getVarLocation(agalVar.name, pi)
                   // trace("Setting location " + agalVar.name + " with location " + location + " to " + agalVar.x)
                //    trace("Setting location " + agalVar.name +  " with location " + (location + 1) + " to " + agalVar.y)
                    if (location >= 0)
                    {
                        setProgramConstantData(location, CDATA_FLOAT1, agalVar.x, pi)
                        setProgramConstantData(location + 1, CDATA_FLOAT1, agalVar.y, pi)
                        setProgramConstantData(location + 2, CDATA_FLOAT1, agalVar.z, pi)
                        setProgramConstantData(location + 3, CDATA_FLOAT1, agalVar.w, pi)
                    }
                }
            }
        }
  */      
/*        
        // Helper to tease out location information for a given AGALVar slot.
        // The location can be used later to infer where to set constant data or
        // which vertex stream to assign where.
        protected function getVarLocation(variable:String, program:ProgramInstance):int
        {
            var idx:int = -1
            var isVertexVar:Boolean = false
            var agalVar:AGALVar = program.vertexShaderVars[variable]
            var isVertexVar:Boolean = (agalVar != null)
            agalVar =  (agalVar != null) ? agalVar : program.fragmentShaderVars[variable]

            if (agalVar)
            {
                if (agalVar.StreamPosition != -1)
                {
                    var position:int = agalVar.StreamPosition
                    var dot:int = agalVar.target.indexOf( "." )
                    if (dot > 0 && (agalVar.target.length - 1) > dot)
                    {
                        var offset:int = 0
                        switch (agalVar.target.charAt(dot+1))
                        {
                            case 'y': offset = offset + 1
                                break
                            case 'z': offset = offset + 2
                                break
                            case 'w': offset = offset + 3
                                break
                        }
                        position += offset
                    }

                    if (agalVar.isProgramConstant) 
                    {
                        position = position * 4
                        idx = (isVertexVar) ? position : 512 + position
                    }
                    else
                        idx = position
                }
            }
            return idx
        }
*/
        // Buffer pooling helpers
        protected function acquireBufferFromPool(numElements:int, data32PerVertex:int, target:uint):DataBuffer
        {
            var isVertexBuffer:Boolean = target == GL_ARRAY_BUFFER
            var key:uint

        if(isVertexBuffer)
            key =  data32PerVertex << 26 | numElements
        else
            key = numElements

            var candidates:BufferPool = isVertexBuffer ? vertexBufferPool[key] : indexBufferPool[key]

            var match:DataBuffer = null
            if (!candidates)
            {
                candidates = new BufferPool()
                if (isVertexBuffer)
                    vertexBufferPool[key] = candidates
                else
                    indexBufferPool[key] = candidates
            }
            
            var db:DataBuffer = candidates.getBuffer(framestamp)
            db.target = target
            db.uploaded = false
            return db
        }

        // Sequential TriStrip index buffer
        private var totalSequentialTriStripCacheSize:int = 0
        private var sequentialTriStripCacheSize:int = 0
        private var indexBufferSequentialTriStrip:DataBuffer = new DataBuffer()

        // Grab an index buffer that will render sequentially packed tristrips as trilist
            protected function acquireSequentialTriStripIndexBuffer(numElements:int):DataBuffer
            {
            // What is the number of elements we actually need
            var triCount:int = (numElements - 2)
            var triIdx:int = 0
            var requiredIndexCount:int = triCount * 3

// The 'false' case will use a shared index buffer that grows to the largest required size
// HOWEVER, it appears that rendering w/ an index buffer that does not match the number of
// vertices bound (largest index in the index buffer > bound vertex count) does not work.
if (false)
{
            // Do we need more entries in the index buffer?
            var bRepackRequired:Boolean = false
            if (context.enableErrorChecking == false)
            {
                bRepackRequired = (requiredIndexCount > sequentialTriStripCacheSize)
            }
            else
            {
                // We have to repack if the size changes at all w/ the error checking enabled
                // Apparently it walks the index buffer to find the max vertex index...
                bRepackRequired = (requiredIndexCount != sequentialTriStripCacheSize)
            }
            // Repacking *every* call works...
            //bRepackRequired = (requiredIndexCount != sequentialTriStripCacheSize)

            if (bRepackRequired)
            {
                //trace("acquireSequentialTriStripIndexBuffer: requiredIndexCount " + requiredIndexCount + ", sequentialTriStripCacheSize " + sequentialTriStripCacheSize)

                indexBufferSequentialTriStrip.target = GL_ELEMENT_ARRAY_BUFFER
                indexBufferSequentialTriStrip.indicesSize = GL_UNSIGNED_SHORT
                indexBufferSequentialTriStrip.data.clear()

                // THIS ONLY WORKS IF THE TRI STRIPS USE SEQUENTIAL VERTEX DATA!!!!
                // Fill in the index buffer
                //@todo. can we just fill in the newly required ones? Possibly faster...
                indexBufferSequentialTriStrip.data.position = 0
                for (triIdx = 0; triIdx < triCount; triIdx += 2)
                {
                    indexBufferSequentialTriStrip.data.writeShort(0 + triIdx)
                    indexBufferSequentialTriStrip.data.writeShort(1 + triIdx)
                    indexBufferSequentialTriStrip.data.writeShort(2 + triIdx)
                    indexBufferSequentialTriStrip.data.writeShort(2 + triIdx)
                    indexBufferSequentialTriStrip.data.writeShort(1 + triIdx)
                    indexBufferSequentialTriStrip.data.writeShort(3 + triIdx)
                }
                indexBufferSequentialTriStrip.data.length = requiredIndexCount * 2
                indexBufferSequentialTriStrip.data.position = 0
                indexBufferSequentialTriStrip.size = requiredIndexCount * 2
//                uploadBuffer(dataBuffer)

                // If we have an index buffer, dispose
                if (indexBufferSequentialTriStrip.indexBuffer != null)
                {
                    indexBufferSequentialTriStrip.indexBuffer.dispose()
                }

                // Create a new index buffer
                indexBufferSequentialTriStrip.indexBuffer = context.createIndexBuffer(requiredIndexCount)
                indexBufferSequentialTriStrip.indexBuffer.uploadFromByteArray(indexBufferSequentialTriStrip.data, 0, 0, requiredIndexCount)
                indexBufferSequentialTriStrip.uploaded = true

                sequentialTriStripCacheSize = requiredIndexCount
            }

            return indexBufferSequentialTriStrip
}
else
{
            var match:DataBuffer = squentialTripStripIndexBufferPool[requiredIndexCount]
            if (match == null)
            {
if (context.enableErrorChecking)
{
    trace("Creating sequential tristrip index buffer of size " + (requiredIndexCount * 2))
}
                match = new DataBuffer()
                squentialTripStripIndexBufferPool[requiredIndexCount] = match

                match.target = GL_ELEMENT_ARRAY_BUFFER
                match.indicesSize = GL_UNSIGNED_SHORT
                match.data.clear()

                // THIS ONLY WORKS IF THE TRI STRIPS USE SEQUENTIAL VERTEX DATA!!!!
                // Fill in the index buffer
                //@todo. can we just fill in the newly required ones? Possibly faster...
                match.data.position = 0
                for (triIdx = 0; triIdx < triCount; triIdx += 2)
                {
                    match.data.writeShort(0 + triIdx)
                    match.data.writeShort(1 + triIdx)
                    match.data.writeShort(2 + triIdx)
                    match.data.writeShort(2 + triIdx)
                    match.data.writeShort(1 + triIdx)
                    match.data.writeShort(3 + triIdx)
                }
                match.data.length = requiredIndexCount * 2
                match.data.position = 0
                match.size = requiredIndexCount * 2

                // If we have an index buffer, dispose
                if (match.indexBuffer != null)
                {
                    match.indexBuffer.dispose()
                }

                // Create a new index buffer
                match.indexBuffer = context.createIndexBuffer(requiredIndexCount)
                match.indexBuffer.uploadFromByteArray(match.data, 0, 0, requiredIndexCount)
                // Clear the byte array
                match.data.clear()
                match.uploaded = true

//if (context.enableErrorChecking)
{
                totalSequentialTriStripCacheSize += requiredIndexCount * 2
                if (
                    (totalSequentialTriStripCacheSize > (1024 * 1024 * 2))
                    )
                {
                    trace("totalSequentialTriStripCacheSize = " + totalSequentialTriStripCacheSize)
                }
}
            }
            
            return match
}
        }
    }
}
    import Stage3DGL.GLAPI;
    import flash.display3D.*;
    import flash.display3D.textures.*;
    import flash.geom.*;
    import flash.utils.*;
    
    class BufferPool    
    {
        public var framestamp:uint = 0
        public var idx:uint = 0
        public var buffers:Vector.<DataBuffer> = new Vector.<DataBuffer>()

        public function getBuffer(fs:uint):DataBuffer
        {
            if(framestamp != fs) {
                framestamp = fs
                idx = 0
            }

            if(idx >= buffers.length)
                buffers.push(new DataBuffer())

            return buffers[idx++]            
        }
    }
        
    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    internal class DataBuffer 
    {
        public var id:uint
        public var target:uint
        public var usage:uint
        public var data:ByteArray
        public var size:uint
        public var indicesSize:uint
        public var stride:uint
        public var uploaded:Boolean
        public var indexBuffer:IndexBuffer3D
        public var vertexBuffer:VertexBuffer3D
        public var inUse:Boolean

    public function DataBuffer() {
        data = new ByteArray()
        data.endian = "littleEndian"
    }
    }
    
    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    class FrameBuffer 
    {
        public var colorTexture:Texture
        public var enableDepthAndStencil:Boolean
        public var lastClearFramestamp:uint
    }
    
    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    class RenderBuffer 
    {
        public var backingTexture:Texture
    }
    
    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    class TextureInstance
    {
        public var texture:Texture
        public var cubeTexture:CubeTexture
        public var mipLevels:uint
        public var params:TextureParams = new TextureParams()
        public var boundType:uint
        public var texID:uint
    }
    
    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    class TextureParams
    {
//        public var boundTexture:uint
        public var GL_TEXTURE_MAX_ANISOTROPY_EXT:Number = -1
        public var GL_TEXTURE_MAG_FILTER:Number = GLAPI.GL_LINEAR
        public var GL_TEXTURE_MIN_FILTER:Number = GLAPI.GL_NEAREST_MIPMAP_LINEAR

        public var GL_TEXTURE_MIN_LOD:Number = -1000.0
        public var GL_TEXTURE_MAX_LOD:Number = 1000.0
        
        public var GL_TEXTURE_WRAP_S:uint = GLAPI.GL_REPEAT
        public var GL_TEXTURE_WRAP_T:uint = GLAPI.GL_REPEAT

        public var GL_TEXTURE_ENV_MODE:uint = GLAPI.GL_MODULATE

//        public function clone():TextureParams
//        {
//            var result:TextureParams = new TextureParams()
//
//            result.boundTexture                             = this.boundTexture
//            result.GL_TEXTURE_MAX_ANISOTROPY_EXT            = this.GL_TEXTURE_MAX_ANISOTROPY_EXT
//            result.GL_TEXTURE_MAG_FILTER                    = this.GL_TEXTURE_MAG_FILTER
//            result.GL_TEXTURE_MIN_FILTER                    = this.GL_TEXTURE_MIN_FILTER
//            result.GL_TEXTURE_WRAP_S                        = this.GL_TEXTURE_WRAP_S
//            result.GL_TEXTURE_WRAP_T                        = this.GL_TEXTURE_WRAP_T
//
//            return result
//        }
    }
    
    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    class VertexBufferAttribute
    {
        public var offset:uint
        public var buffer:DataBuffer
        public var stride:uint
        public var size:uint
        public var type:uint
        public var normalize:Boolean
        public var enabled:Boolean = false
        public var isGeneric:Boolean = true
    }
    
    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    class ShaderInstance
    {
        public var shaderType:uint
        public var source:String
    }
        
    // ===========================================================================
    //  Class
    // ---------------------------------------------------------------------------
    class ProgramInstance
    {
        public var program:Program3D
        public var id:uint
        public var vertexShader:ShaderInstance = null
        public var fragmentShader:ShaderInstance = null
        public var attributePositions:Dictionary = new Dictionary()
        public var uniformPositions:Dictionary = new Dictionary()
        public var attributeNames:Dictionary = new Dictionary()
        public var uniformNames:Dictionary = new Dictionary()
        public var positionsBuffer:DataBuffer
        public var positionsOffset:uint = 0
        public var textureCoordsBuffer:DataBuffer
        public var textureCoordsOffset:uint = 0
        public var lightMapCoordsOffset:uint = 0
        public var activeSamplers:Vector.<Boolean> = new Vector.<Boolean>(8)

    public var vertexConstantsDirty:Boolean = true
        public var vertexConstantsData:Vector.<Number> = new Vector.<Number>()
    public var fragmentConstantsDirty:Boolean = true
        public var fragmentConstantsData:Vector.<Number> = new Vector.<Number>(4)

    public function updateConstants(context:Context3D):void
    {
        if (vertexConstantsDirty && vertexConstantsData.length) {
//                 if (id == 1)
//                 {
//                     trace("Vertex Data Length: " + vertexConstantsData.length)
//                     for (var i:int = 0; i < vertexConstantsData.length; i++)
//                         trace("Value at " + i + ": " + vertexConstantsData[i])
//                 }
                    context.setProgramConstantsFromVector( Context3DProgramType.VERTEX, 0, vertexConstantsData)
            vertexConstantsDirty = false
        }
        if (fragmentConstantsDirty && fragmentConstantsData.length) {
//                 if (id == 1)
//                 {
//                     trace("Fragment Data Length: " + fragmentConstantsData.length)
//                     for (var i:int = 0; i < fragmentConstantsData.length; i++)
//                         trace("Value at " + i + ": " + fragmentConstantsData[i])
//                 }
                    context.setProgramConstantsFromVector( Context3DProgramType.FRAGMENT, 0, fragmentConstantsData)
            fragmentConstantsDirty = false
        }
    }
        
        public var vertexShaderVars:Dictionary
    public var vertexStreamIndicies:Vector.<Boolean> = new Vector.<Boolean>(128)
        public var fragmentShaderVars:Dictionary

        public var lightMapCoordinateScaleBias:Vector.<Number>
        
        public var hasLocalToWorld:Boolean = false
        public var hasLocalToProjection:Boolean = false
        public var hasViewProjection:Boolean = false
        public var hasTextureCoords:Boolean = false
        public var hasLightmapCoords:Boolean = false
        public var hasPositions:Boolean = false
        public var hasBasicFragmentShader:Boolean = false
        public var hasLightMap:Boolean = false
        public var hasBaseTexture:Boolean = false
    }

// ===========================================================================
//  Class
// ---------------------------------------------------------------------------
//class GLDisplayList
//{
//    public var executeOnCompile:Boolean = false
//    public var vertexBuffer:VertexBuffer3D
//    public var indexBuffer:IndexBuffer3D
//    public var program:FixedFunctionProgramInstance
//    public var textureSamplers:Vector.<uint> = new Vector.<uint>(8)
//
//    // For debugging:
//    public var vertexData:Vector.<Number>
//    public var indexData:Vector.<uint>
//}


// ===========================================================================
//  Class
// ---------------------------------------------------------------------------
class VertexBufferBuilder
{
    // FIXME (egeorgie): optimize
    public var mode:uint
    //public var data:Vector.<Number>
//    public var tx:Vector.<Number>
//    public var pos:Vector.<Number>
//    public var color:Vector.<Number>
//    public var normal:Vector.<Number>
    
    // position
    public var x:Number = 0
    public var y:Number = 0
    public var z:Number = 0
    
    // color
    public var r:Number = 1
    public var g:Number = 1
    public var b:Number = 1
    public var a:Number = 1
    
    // normal
    public var nx:Number = 0
    public var ny:Number = 0
    public var nz:Number = 0
    
    // texture
    public var tx:Number = 0
    public var ty:Number = 0
   
    public var flags:uint = 0
    
    public static const HAS_COLOR:uint      = 0x00000001
    public static const HAS_TEXTURE2D:uint  = 0x00000002
    public static const HAS_NORMAL:uint     = 0x00000004
    public static const TEX_GEN_S_SPHERE:uint   = 0x00000008
    public static const TEX_GEN_T_SPHERE:uint   = 0x00000010
    
    //public var dataVector:Vector.<Number> = new Vector.<Number>()
    public var data:ByteArray
    public var count:int
    
    public function VertexBufferBuilder()
    {
        data = new ByteArray()
        data.endian = "littleEndian"
    }
    
    public function reset():void
    {
        // No need to reset vertex, as those will always be fully defined?
//        x = y = z = 0
//        r = g = b = a = 1
//        nz = ny = nz = tx = ty = 0
        flags = 0
        data.position = 0
        count = 0

//        dataVector.length = 0
    }
    
    public function push():void
    {
//        if ((flags & HAS_TEXTURE2D) != 0)
//            trace("glVertex("+ x + ", " + y + ", " + z + ", tx = " + tx + ", ty = " + ty + ")")
//        else 
//            trace("glVertex("+ x + ", " + y + ", " + z + ")")
        
        // FIXME (egeorgie): optimize
  //      dataVector.push(x, y, z, r, g, b, a, nx, ny, nz, tx, ty)
        data.writeFloat(x)
        data.writeFloat(y)
        data.writeFloat(z)
        data.writeFloat(r)
        data.writeFloat(g)
        data.writeFloat(b)
        data.writeFloat(a)
        data.writeFloat(nx)
        data.writeFloat(ny)
        data.writeFloat(nz)
        data.writeFloat(tx)
        data.writeFloat(ty)
        ++count
    }
    
}


// ===========================================================================
//  Class
// ---------------------------------------------------------------------------
class FixedFunctionProgramInstance
{
    public var program:Program3D
    public var vertexStreamUsageFlags:uint = 0
    public var hasTexture:Boolean = false
    public var key:String
}

// ===========================================================================
//  Class
// ---------------------------------------------------------------------------
class TraceLog
{
    public function send(value:String):void
    {
        trace(value)
    }
}


/**
 *  Represents the vertices as defined between calls of glBeing() and glEnd().
 *  Holds and instance to the associated shader program.
 */
class VertexStream
{
    public var vertexBuffer:VertexBuffer3D
    public var indexBuffer:IndexBuffer3D
//    public var triangleCount:int
    public var vertexFlags:uint
    public var program:FixedFunctionProgramInstance
    public var polygonOffset:Boolean = false
}

/**
 *  Represents consequtive context state changes as defined between calls of glNewList() and glEndList().
 *  A single CommandList can have multiple context state changes.  
 */
class ContextState
{
    public var textureSamplers:Vector.<int>// = new Vector.<uint>(8)
    public var material:Material
}

/**
 *  Records of the OpenGL commands between calls of glNewList() and glEndList().  
 */
class CommandList
{
    // Used during building, move out?
    public var executeOnCompile:Boolean = false
    public var activeState:ContextState = null

    // Storage
    public var commands:Vector.<Object> = new Vector.<Object>()
    
    public function ensureActiveState():ContextState
    {
        if (!activeState)
        {
            activeState = new ContextState()
            activeState.textureSamplers = new Vector.<int>(8)
            for (var i:int = 0; i < 8; i++)
            {
                activeState.textureSamplers[i] = -1 // Set to 'undefined'
            }
            
            activeState.material = new Material() // don't initialize, so we know what has changed.
        }
        return activeState
    }
}

class Light
{
    public var position:Vector.<Number>
    public var ambient:Vector.<Number>
    public var diffuse:Vector.<Number>
    public var specular:Vector.<Number>
    // FIXME (klin): No spotlight for now...neverball doesn't use it
    
    public function Light(init:Boolean = false, isLight0:Boolean = false)
    {
        if (init)
        {
            position = new <Number>[0, 0, 1, 0]
            ambient = new <Number>[0, 0, 0, 1]
            diffuse = (isLight0) ? new <Number>[1, 1, 1, 1] :
                                   new <Number>[0, 0, 0, 1]
            specular = (isLight0) ? new <Number>[1, 1, 1, 1] :
                                    new <Number>[0, 0, 0, 1]
        }
    }
    
    public function createClone():Light
    {
        var clone:Light = new Light(false)
        clone.position = (position) ? position.concat() : null
        clone.ambient = (ambient) ? ambient.concat() : null
        clone.diffuse = (diffuse) ? diffuse.concat() : null
        clone.specular = (specular) ? specular.concat() : null
        return clone
    }
}

class Material
{
    public var ambient:Vector.<Number>
    public var diffuse:Vector.<Number>
    public var specular:Vector.<Number>
    public var shininess:Number
    public var emission:Vector.<Number>

    public function Material(init:Boolean = false)
    {
        // If init is true, we initialize to default values.
        if (init)
        {
            ambient = new <Number>[0.2, 0.2, 0.2, 1.0]
            diffuse = new <Number>[0.8, 0.8, 0.8, 1.0]
            specular = new <Number>[0.0, 0.0, 0.0, 1.0]
            shininess = 0.0
            emission = new <Number>[0.0, 0.0, 0.0, 1.0]
        }
    }
    
    public function createClone():Material
    {
        var clone:Material = new Material(false)
        clone.ambient = (ambient) ? ambient.concat() : null
        clone.diffuse = (diffuse) ? diffuse.concat() : null
        clone.specular = (specular) ? specular.concat() : null
        clone.shininess = shininess
        clone.emission = (emission) ? emission.concat() : null
        return clone
    }
    
}

class LightingState
{
    public var enableColorMaterial:Boolean // GL_COLOR_MATERIAL enable bit
    // ignore GL_COLOR_MATERIAL_FACE value
    // ignore Color material parameters that are tracking the current color
    // ignore Ambient scene color
    // ignore GL_LIGHT_MODEL_LOCAL_VIEWER value
    // ignore GL_LIGHT_MODEL_TWO_SIDE setting
    public var enableLighting:Boolean // GL_LIGHTING enable bit
    public var lightsEnabled:Vector.<Boolean>
    public var lights:Vector.<Light>
    public var contextMaterial:Material
    // ignore GL_SHADE_MODEL
    
}

class BufferNode
{
    public var buffer:VertexBuffer3D
    public var prev:int
    public var next:int
    public var count:uint
    public var hash:uint
    // Debug:
    // public var src:ByteArray
}


class VertexBufferPool
{
    private var hashToIndex:Dictionary = new Dictionary()
    private var bufferToIndex:Dictionary = new Dictionary(true)
    private var buffers:Vector.<BufferNode> = new Vector.<BufferNode>()
    private var tail:int = -1
    private var head:int = -1
    private var prevFrame:int = -1 // index of MRU node previous frame
    private var prevPrevFrame:int = -1 // index of MRU node two frames ago
    
    public function acquire(hash:uint, count:uint, data:ByteArray, dataPtr:uint):VertexBuffer3D
    {
//        // Debug:
//        var h:uint = calcHash(count, data, dataPtr)
//        if (h != hash)
//            trace("Hashes don't match: " + hash + " " + h)
//        else
//            trace("Hashes match: " + hash)
        
        if (!(hash in hashToIndex))
            return null
        
        var index:int = hashToIndex[hash]
        var node:BufferNode = buffers[index]
        if (node.count != count)
            throw("Collision in count " + node.count + " != " + count)

//        // Debug:
//        var src:ByteArray = node.src
//        src.position = 0
//        data.position = dataPtr
//        for (var i:int = 0; i < src.length / 4; i++)
//            if (src.readUnsignedInt() != data.readUnsignedInt())
//            {
//                trace("Collision in data at vertex " + (i / 12) + ", offset " + (i % 12))
//                // print out the source & dst data
//                {
//                    src.position = 0
//                    data.position = dataPtr
//                    for (i = 0; i < src.length / 4; i++)
//                    {
//                        var value:Number = src.readFloat()
//                        var value1:Number = data.readFloat()
//                        if (value != value1)
//                            trace("Difference: at position " + i + ": " + value + " != " + value1) 
//                    }
//                    
//                    // Calculate improved hash function:
//                    src.position = 0
//                    data.position = dataPtr
//                    var hash1:uint = calcHash(count, src, 0)
//                    var hash2:uint = calcHash(count, data, dataPtr)
//                    trace("Computed Hashes are " + hash1 + " (stored data), " + hash2 + " (new data), stored hash is " + node.hash)
//                    return node.buffer
//                }
//            }

        return node.buffer  
    }

    // Debug:
    static public function calcHash(count:uint, data:ByteArray, dataPtr:uint):uint
    {
        const offset_basis:uint = 2166136261
        // 32 bit FNV_prime = 224 + 28 + 0x93 = 16777619

        const prime:uint = 16777619
        var hash:uint = offset_basis

        data.position = dataPtr
        for (var i:int = 0; i < count * 12 * 4; i++)
        {
            var v:uint = data.readUnsignedByte()
            
            hash = hash ^ v
            hash = hash * prime
        }
        return hash
    }

    public function allocateOrReuse(hash:uint, count:uint, data:ByteArray, dataPtr:uint, context:Context3D):VertexBuffer3D
    {
        var index:int = reuseBufferNode(count)
        var node:BufferNode
        if (index != -1)
        {
            node = buffers[index]
            // Remove the old entry
            delete hashToIndex[node.hash]
        }
        else
        {
            node = new BufferNode()
            node.count = count
            node.buffer = context.createVertexBuffer(count, 12)
            index = insertNode(node)
        }

//        // Debug:
//        node.src = new ByteArray()
//        node.src.endian = data.endian
//        data.position = dataPtr
//        var length:int = count * 12 * 4
//        node.src.length = length
//        node.src.position = 0
//        data.readBytes(node.src, 0, length)
//        trace("Allocating: passed on hash " + hash + ", computed hash " + calcHash(count, data, dataPtr) + ", computed on copy " + calcHash(count, node.src, 0)) 

        node.buffer.uploadFromByteArray(data, dataPtr, 0, count)
        bufferToIndex[node.buffer] = index
        hashToIndex[hash] = index
        node.hash = hash
        return node.buffer
    }
    
    private function reuseBufferNode(count:uint):int
    {
        if (prevPrevFrame == -1)
            return -1

        // Iterate backwards, starting from the tail
        var current:int = tail
        var node:BufferNode = null
        while (current != -1)
        {
            node = buffers[ current ]
            
            // Make sure we don't reuse a buffer that's been used this or last frame
            if (node.next == prevPrevFrame)
                return -1

            // Found a node with correct count
            if (node.count == count)
                return current

            current = node.prev
        }
        return -1
    }
    
    private function insertNode(node:BufferNode):int
    {
        var index:int = buffers.length
        buffers.push(node)
        if (head == -1)
        {
            tail = index
        }
        else
        {
            var headNode:BufferNode = buffers[head]
            headNode.prev = index
        }
        node.next = head
        node.prev = -1
        head = index
        return index
    }
    
    public function markInUse(buffer:VertexBuffer3D):void
    {
        if (!(buffer in bufferToIndex))
            return
        
        var index:int = bufferToIndex[buffer]
        
        // Already at the head?
        if (head == index)
            return

        var node:BufferNode = buffers[index]
        
        // Make sure we adjust the pointers for MRU last Frame and the frame before
        if (prevPrevFrame == index)
            prevPrevFrame = node.next
        if (prevFrame == index)
            prevFrame = node.next

        // Update the neighboring nodes
        var prevNode:BufferNode = node.prev != -1 ? buffers[node.prev] : null
        var nextNode:BufferNode = node.next != -1 ? buffers[node.next] : null
        if (prevNode)
            prevNode.next = node.next
        if (nextNode)
            nextNode.prev = node.prev
        
        // Update the tail
        if (tail == index)
            tail = node.prev

        // Update the head
        var headNode:BufferNode = buffers[head]
        headNode.prev = index

        // Make the node the head of the list
        node.next = head
        node.prev = -1
        head = index
    }
    
    public function nextFrame():void
    {
        prevPrevFrame = prevFrame    
        prevFrame = head
        
        // FIXME (egeorgie): cleanup for nodes at the tail if we're exceeding limit?

        //trace(print)
    }
    
    // For debugging:
    private function get print():String
    {
        var output:String = ""
        var current:int = head
        while (current != -1)
        {
            var n:String = current.toString()
            if (prevFrame == current || prevPrevFrame == current)
                output += " | " + current.toString()
            else
                output += " " + current.toString()

            var node:BufferNode = buffers[current]
            current = node.next
        }
        if (prevFrame == -1)
            output += " |"
        if (prevPrevFrame == -1)
            output += " |"
        return output
    }
}
