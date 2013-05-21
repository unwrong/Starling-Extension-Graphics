package starling.display.materials
{
	import flash.display3D.Context3D;
	import flash.display3D.Program3D;
	import flash.utils.Dictionary;
	
	import starling.display.Graphics;
	import starling.display.shaders.IShader;

	public class Program3DCache
	{
		private static var uid							:int = 0;
		private static var uidByShaderTable				:Dictionary = new Dictionary(true);
		private static var programByUIDTable			:Object = {};
		private static var uidByProgramTable			:Dictionary = new Dictionary(false);
		private static var numReferencesByProgramTable	:Dictionary = new Dictionary();
		private static var _autoDelete					:Boolean = true;
		
		// Specify either:
		// 1) Off: Explicit flushing of non-referenced programs using flushNonReferencedPrograms()
		// 2) On: Programs are flushed when there reference count reaches zero
		public static function set autoDelete(on:Boolean):void {_autoDelete = on;}
		public static function get autoDelete():Boolean {return _autoDelete;}
		
		internal static function getProgram3D( context:Context3D, vertexShader:IShader, fragmentShader:IShader ):Program3D
		{
			var vertexShaderUID:int = uidByShaderTable[vertexShader];
			if ( vertexShaderUID == 0 )
			{
				vertexShaderUID = uidByShaderTable[vertexShader] = ++uid;
			}
			
			var fragmentShaderUID:int = uidByShaderTable[fragmentShader];
			if ( fragmentShaderUID == 0 )
			{
				fragmentShaderUID = uidByShaderTable[fragmentShader] = ++uid;
			}
			
			var program3DUID:String = vertexShaderUID + "_" + fragmentShaderUID;
			
			var program3D:Program3D = programByUIDTable[program3DUID];
			if ( program3D == null )
			{
				program3D = programByUIDTable[program3DUID] = context.createProgram();
				uidByProgramTable[program3D] = program3DUID;
				program3D.upload( vertexShader.opCode, fragmentShader.opCode );
				numReferencesByProgramTable[program3D] = 0;
			}
			
			numReferencesByProgramTable[program3D]++;
			
			return program3D;
		}
		
		internal static function releaseProgram3D( program3D:Program3D ):void
		{
			if (numReferencesByProgramTable[program3D] == null)
			{
				throw( new Error( "Program3D is not in cache" ) );
				return;
			}
			
			var numReferences:int = numReferencesByProgramTable[program3D];
			if (!_autoDelete && numReferences == 0)
			{
				throw( new Error( "Reference count below zero" ) );
				return;
			}
			numReferences--;
			
			if ( numReferences == 0 && _autoDelete )
			{
				deleteInCache(program3D);
			}
			
			numReferencesByProgramTable[program3D] = numReferences;
		}
		
		
		// Abstracted internal function for deleting a program from the cache
		// Either invoked automatically when reference count reaches zero or
		// through flushNonReferencedPrograms().
		private static function deleteInCache(program3D:Program3D):void {
			program3D.dispose();
			delete numReferencesByProgramTable[program3D];
			var program3DUID:String = uidByProgramTable[program3D];
			delete programByUIDTable[program3DUID];
			delete uidByProgramTable[program3D];
			return;
		}
		
		// If setAutoDelete(false), use this function to flush non-referenced programs
		// at any point during the game loop.  Useful in situations where all objects
		// using a particular program are redrawn every frame.
		public static function flushNonReferencedPrograms():void
		{
			var programsToDelete:Array = new Array();
			for (var program3D:Program3D in numReferencesByProgramTable) 
			{
				if (numReferencesByProgramTable[program3D] == 0)
				{
					programsToDelete.push(program3D);
				}
			}
			
			for each (program3D in programsToDelete) 
			{
				deleteInCache(program3D);
			}
			
		}
		
	}
}