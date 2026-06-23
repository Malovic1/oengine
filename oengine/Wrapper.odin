package oengine

import rl "vendor:raylib"

rl_InitWindow              :: rl.InitWindow
rl_CloseWindow             :: rl.CloseWindow
rl_WindowShouldClose       :: rl.WindowShouldClose
rl_IsWindowReady           :: rl.IsWindowReady
rl_IsWindowFullscreen      :: rl.IsWindowFullscreen
rl_IsWindowHidden          :: rl.IsWindowHidden
rl_IsWindowMinimized       :: rl.IsWindowMinimized
rl_IsWindowMaximized       :: rl.IsWindowMaximized
rl_IsWindowFocused         :: rl.IsWindowFocused
rl_IsWindowResized         :: rl.IsWindowResized
rl_IsWindowState           :: rl.IsWindowState
rl_SetWindowState          :: rl.SetWindowState
rl_ClearWindowState        :: rl.ClearWindowState
rl_ToggleFullscreen        :: rl.ToggleFullscreen
rl_ToggleBorderlessWindowed:: rl.ToggleBorderlessWindowed
rl_MaximizeWindow          :: rl.MaximizeWindow
rl_MinimizeWindow          :: rl.MinimizeWindow
rl_RestoreWindow           :: rl.RestoreWindow
rl_SetWindowIcon           :: rl.SetWindowIcon
rl_SetWindowIcons          :: rl.SetWindowIcons
rl_SetWindowTitle          :: rl.SetWindowTitle
rl_SetWindowPosition       :: rl.SetWindowPosition
rl_SetWindowMonitor        :: rl.SetWindowMonitor
rl_SetWindowMinSize        :: rl.SetWindowMinSize
rl_SetWindowMaxSize        :: rl.SetWindowMaxSize
rl_SetWindowSize           :: rl.SetWindowSize
rl_SetWindowOpacity        :: rl.SetWindowOpacity
rl_SetWindowFocused        :: rl.SetWindowFocused
rl_GetWindowHandle         :: rl.GetWindowHandle
rl_GetScreenWidth          :: rl.GetScreenWidth
rl_GetScreenHeight         :: rl.GetScreenHeight
rl_GetRenderWidth          :: rl.GetRenderWidth
rl_GetRenderHeight         :: rl.GetRenderHeight
rl_GetMonitorCount         :: rl.GetMonitorCount
rl_GetCurrentMonitor       :: rl.GetCurrentMonitor
rl_GetMonitorPosition      :: rl.GetMonitorPosition
rl_GetMonitorWidth         :: rl.GetMonitorWidth
rl_GetMonitorHeight        :: rl.GetMonitorHeight
rl_GetMonitorPhysicalWidth :: rl.GetMonitorPhysicalWidth
rl_GetMonitorPhysicalHeight:: rl.GetMonitorPhysicalHeight
rl_GetMonitorRefreshRate   :: rl.GetMonitorRefreshRate
rl_GetWindowPosition       :: rl.GetWindowPosition
rl_GetWindowScaleDPI       :: rl.GetWindowScaleDPI
rl_GetMonitorName          :: rl.GetMonitorName
rl_SetClipboardText        :: rl.SetClipboardText
rl_GetClipboardText        :: rl.GetClipboardText
rl_EnableEventWaiting      :: rl.EnableEventWaiting
rl_DisableEventWaiting     :: rl.DisableEventWaiting

rl_ShowCursor      :: rl.ShowCursor
rl_HideCursor      :: rl.HideCursor
rl_IsCursorHidden  :: rl.IsCursorHidden
rl_EnableCursor    :: rl.EnableCursor
rl_DisableCursor   :: rl.DisableCursor
rl_IsCursorOnScreen:: rl.IsCursorOnScreen

rl_ClearBackground   :: rl.ClearBackground
rl_BeginDrawing      :: rl.BeginDrawing
rl_EndDrawing        :: rl.EndDrawing
rl_BeginMode2D       :: rl.BeginMode2D
rl_EndMode2D         :: rl.EndMode2D
rl_BeginMode3D       :: rl.BeginMode3D
rl_EndMode3D         :: rl.EndMode3D
rl_BeginTextureMode  :: rl.BeginTextureMode
rl_EndTextureMode    :: rl.EndTextureMode
rl_BeginShaderMode   :: rl.BeginShaderMode
rl_EndShaderMode     :: rl.EndShaderMode
rl_BeginBlendMode    :: rl.BeginBlendMode
rl_EndBlendMode      :: rl.EndBlendMode
rl_BeginScissorMode  :: rl.BeginScissorMode
rl_EndScissorMode    :: rl.EndScissorMode
rl_BeginVrStereoMode :: rl.BeginVrStereoMode
rl_EndVrStereoMode   :: rl.EndVrStereoMode

rl_SetTargetFPS :: rl.SetTargetFPS
rl_GetFrameTime :: rl.GetFrameTime
rl_GetTime      :: rl.GetTime
rl_GetFPS       :: rl.GetFPS

rl_IsKeyPressed       :: rl.IsKeyPressed
rl_IsKeyPressedRepeat :: rl.IsKeyPressedRepeat
rl_IsKeyDown          :: rl.IsKeyDown
rl_IsKeyReleased      :: rl.IsKeyReleased
rl_IsKeyUp            :: rl.IsKeyUp
rl_GetKeyPressed      :: rl.GetKeyPressed
rl_GetCharPressed     :: rl.GetCharPressed
rl_SetExitKey         :: rl.SetExitKey

rl_IsMouseButtonPressed :: rl.IsMouseButtonPressed
rl_IsMouseButtonDown    :: rl.IsMouseButtonDown
rl_IsMouseButtonReleased:: rl.IsMouseButtonReleased
rl_IsMouseButtonUp      :: rl.IsMouseButtonUp
rl_GetMouseX            :: rl.GetMouseX
rl_GetMouseY            :: rl.GetMouseY
rl_GetMousePosition     :: rl.GetMousePosition
rl_GetMouseDelta        :: rl.GetMouseDelta
rl_SetMousePosition     :: rl.SetMousePosition
rl_SetMouseOffset       :: rl.SetMouseOffset
rl_SetMouseScale        :: rl.SetMouseScale
rl_GetMouseWheelMove    :: rl.GetMouseWheelMove
rl_GetMouseWheelMoveV   :: rl.GetMouseWheelMoveV
rl_SetMouseCursor       :: rl.SetMouseCursor

rl_DrawPixel                     :: rl.DrawPixel
rl_DrawPixelV                    :: rl.DrawPixelV
rl_DrawLine                      :: rl.DrawLine
rl_DrawLineV                     :: rl.DrawLineV
rl_DrawLineEx                    :: rl.DrawLineEx
rl_DrawLineStrip                 :: rl.DrawLineStrip
rl_DrawLineBezier                :: rl.DrawLineBezier
rl_DrawCircle                    :: rl.DrawCircle
rl_DrawCircleV                   :: rl.DrawCircleV
rl_DrawCircleGradient            :: rl.DrawCircleGradient
rl_DrawCircleSector              :: rl.DrawCircleSector
rl_DrawCircleSectorLines         :: rl.DrawCircleSectorLines
rl_DrawCircleLines               :: rl.DrawCircleLines
rl_DrawCircleLinesV              :: rl.DrawCircleLinesV
rl_DrawEllipse                   :: rl.DrawEllipse
rl_DrawEllipseLines              :: rl.DrawEllipseLines
rl_DrawRing                      :: rl.DrawRing
rl_DrawRingLines                 :: rl.DrawRingLines
rl_DrawRectangle                 :: rl.DrawRectangle
rl_DrawRectangleV                :: rl.DrawRectangleV
rl_DrawRectangleRec              :: rl.DrawRectangleRec
rl_DrawRectanglePro              :: rl.DrawRectanglePro
rl_DrawRectangleGradientV        :: rl.DrawRectangleGradientV
rl_DrawRectangleGradientH        :: rl.DrawRectangleGradientH
rl_DrawRectangleGradientEx       :: rl.DrawRectangleGradientEx
rl_DrawRectangleLines            :: rl.DrawRectangleLines
rl_DrawRectangleLinesEx          :: rl.DrawRectangleLinesEx
rl_DrawRectangleRounded          :: rl.DrawRectangleRounded
rl_DrawRectangleRoundedLines     :: rl.DrawRectangleRoundedLines
rl_DrawTriangle                  :: rl.DrawTriangle
rl_DrawTriangleLines             :: rl.DrawTriangleLines
rl_DrawTriangleFan               :: rl.DrawTriangleFan
rl_DrawTriangleStrip             :: rl.DrawTriangleStrip
rl_DrawPoly                      :: rl.DrawPoly
rl_DrawPolyLines                 :: rl.DrawPolyLines
rl_DrawPolyLinesEx               :: rl.DrawPolyLinesEx

rl_DrawSplineLinear                 :: rl.DrawSplineLinear
rl_DrawSplineBasis                  :: rl.DrawSplineBasis
rl_DrawSplineCatmullRom             :: rl.DrawSplineCatmullRom
rl_DrawSplineBezierQuadratic        :: rl.DrawSplineBezierQuadratic
rl_DrawSplineBezierCubic            :: rl.DrawSplineBezierCubic
rl_DrawSplineSegmentLinear          :: rl.DrawSplineSegmentLinear
rl_DrawSplineSegmentBasis           :: rl.DrawSplineSegmentBasis
rl_DrawSplineSegmentCatmullRom      :: rl.DrawSplineSegmentCatmullRom
rl_DrawSplineSegmentBezierQuadratic :: rl.DrawSplineSegmentBezierQuadratic
rl_DrawSplineSegmentBezierCubic     :: rl.DrawSplineSegmentBezierCubic

rl_GetSplinePointLinear        :: rl.GetSplinePointLinear
rl_GetSplinePointBasis         :: rl.GetSplinePointBasis
rl_GetSplinePointCatmullRom    :: rl.GetSplinePointCatmullRom
rl_GetSplinePointBezierQuad    :: rl.GetSplinePointBezierQuad
rl_GetSplinePointBezierCubic   :: rl.GetSplinePointBezierCubic

rl_CheckCollisionRecs          :: rl.CheckCollisionRecs
rl_CheckCollisionCircles       :: rl.CheckCollisionCircles
rl_CheckCollisionCircleRec     :: rl.CheckCollisionCircleRec
rl_CheckCollisionPointRec      :: rl.CheckCollisionPointRec
rl_CheckCollisionPointCircle   :: rl.CheckCollisionPointCircle
rl_CheckCollisionPointTriangle :: rl.CheckCollisionPointTriangle
rl_CheckCollisionPointLine     :: rl.CheckCollisionPointLine
rl_CheckCollisionPointPoly     :: rl.CheckCollisionPointPoly
rl_CheckCollisionLines         :: rl.CheckCollisionLines
rl_GetCollisionRec             :: rl.GetCollisionRec

rl_LoadImage                 :: rl.LoadImage
rl_LoadImageRaw              :: rl.LoadImageRaw
rl_LoadImageAnim             :: rl.LoadImageAnim
rl_LoadImageFromMemory       :: rl.LoadImageFromMemory
rl_LoadImageFromTexture      :: rl.LoadImageFromTexture
rl_LoadImageFromScreen       :: rl.LoadImageFromScreen
rl_UnloadImage               :: rl.UnloadImage
rl_ExportImage               :: rl.ExportImage
rl_ExportImageToMemory       :: rl.ExportImageToMemory
rl_ExportImageAsCode         :: rl.ExportImageAsCode

rl_GenImageColor           :: rl.GenImageColor
rl_GenImageGradientLinear  :: rl.GenImageGradientLinear
rl_GenImageGradientRadial  :: rl.GenImageGradientRadial
rl_GenImageGradientSquare  :: rl.GenImageGradientSquare
rl_GenImageChecked         :: rl.GenImageChecked
rl_GenImageWhiteNoise      :: rl.GenImageWhiteNoise
rl_GenImagePerlinNoise     :: rl.GenImagePerlinNoise
rl_GenImageCellular        :: rl.GenImageCellular
rl_GenImageText            :: rl.GenImageText

rl_ImageCopy             :: rl.ImageCopy
rl_ImageFromImage        :: rl.ImageFromImage
rl_ImageText             :: rl.ImageText
rl_ImageTextEx           :: rl.ImageTextEx
rl_ImageFormat           :: rl.ImageFormat
rl_ImageToPOT            :: rl.ImageToPOT
rl_ImageCrop             :: rl.ImageCrop
rl_ImageAlphaCrop        :: rl.ImageAlphaCrop
rl_ImageAlphaClear       :: rl.ImageAlphaClear
rl_ImageAlphaMask        :: rl.ImageAlphaMask
rl_ImageAlphaPremultiply :: rl.ImageAlphaPremultiply
rl_ImageBlurGaussian     :: rl.ImageBlurGaussian
rl_ImageResize           :: rl.ImageResize
rl_ImageResizeNN         :: rl.ImageResizeNN
rl_ImageResizeCanvas     :: rl.ImageResizeCanvas
rl_ImageMipmaps          :: rl.ImageMipmaps
rl_ImageDither           :: rl.ImageDither
rl_ImageFlipVertical     :: rl.ImageFlipVertical
rl_ImageFlipHorizontal   :: rl.ImageFlipHorizontal
rl_ImageRotate           :: rl.ImageRotate
rl_ImageRotateCW         :: rl.ImageRotateCW
rl_ImageRotateCCW        :: rl.ImageRotateCCW
rl_ImageColorTint        :: rl.ImageColorTint
rl_ImageColorInvert      :: rl.ImageColorInvert
rl_ImageColorGrayscale   :: rl.ImageColorGrayscale
rl_ImageColorContrast    :: rl.ImageColorContrast
rl_ImageColorBrightness  :: rl.ImageColorBrightness
rl_ImageColorReplace     :: rl.ImageColorReplace
rl_LoadImageColors       :: rl.LoadImageColors
rl_LoadImagePalette      :: rl.LoadImagePalette
rl_UnloadImageColors     :: rl.UnloadImageColors
rl_UnloadImagePalette    :: rl.UnloadImagePalette
rl_GetImageAlphaBorder   :: rl.GetImageAlphaBorder
rl_GetImageColor         :: rl.GetImageColor

rl_ImageClearBackground   :: rl.ImageClearBackground
rl_ImageDrawPixel         :: rl.ImageDrawPixel
rl_ImageDrawPixelV        :: rl.ImageDrawPixelV
rl_ImageDrawLine          :: rl.ImageDrawLine
rl_ImageDrawLineV         :: rl.ImageDrawLineV
rl_ImageDrawCircle        :: rl.ImageDrawCircle
rl_ImageDrawCircleV       :: rl.ImageDrawCircleV
rl_ImageDrawCircleLines   :: rl.ImageDrawCircleLines
rl_ImageDrawCircleLinesV  :: rl.ImageDrawCircleLinesV
rl_ImageDrawRectangle     :: rl.ImageDrawRectangle
rl_ImageDrawRectangleV    :: rl.ImageDrawRectangleV
rl_ImageDrawRectangleRec  :: rl.ImageDrawRectangleRec
rl_ImageDrawRectangleLines:: rl.ImageDrawRectangleLines
rl_ImageDraw              :: rl.ImageDraw
rl_ImageDrawText          :: rl.ImageDrawText
rl_ImageDrawTextEx        :: rl.ImageDrawTextEx

rl_LoadTexture           :: rl.LoadTexture
rl_LoadTextureFromImage  :: rl.LoadTextureFromImage
rl_LoadTextureCubemap    :: rl.LoadTextureCubemap
rl_LoadRenderTexture     :: rl.LoadRenderTexture
rl_UnloadTexture         :: rl.UnloadTexture
rl_UnloadRenderTexture   :: rl.UnloadRenderTexture
rl_UpdateTexture         :: rl.UpdateTexture
rl_UpdateTextureRec      :: rl.UpdateTextureRec

rl_GenTextureMipmaps :: rl.GenTextureMipmaps
rl_SetTextureFilter  :: rl.SetTextureFilter
rl_SetTextureWrap    :: rl.SetTextureWrap

rl_DrawTexture        :: rl.DrawTexture
rl_DrawTextureV       :: rl.DrawTextureV
rl_DrawTextureEx      :: rl.DrawTextureEx
rl_DrawTextureRec     :: rl.DrawTextureRec
rl_DrawTexturePro     :: rl.DrawTexturePro
rl_DrawTextureNPatch  :: rl.DrawTextureNPatch

rl_Fade                :: rl.Fade
rl_ColorToInt          :: rl.ColorToInt
rl_ColorNormalize      :: rl.ColorNormalize
rl_ColorFromNormalized :: rl.ColorFromNormalized
rl_ColorToHSV          :: rl.ColorToHSV
rl_ColorFromHSV        :: rl.ColorFromHSV
rl_ColorTint           :: rl.ColorTint
rl_ColorBrightness     :: rl.ColorBrightness
rl_ColorContrast       :: rl.ColorContrast
rl_ColorAlpha          :: rl.ColorAlpha
rl_ColorAlphaBlend     :: rl.ColorAlphaBlend
rl_GetColor            :: rl.GetColor
rl_GetPixelColor       :: rl.GetPixelColor
rl_SetPixelColor       :: rl.SetPixelColor
rl_GetPixelDataSize    :: rl.GetPixelDataSize

rl_GetFontDefault        :: rl.GetFontDefault
rl_LoadFont              :: rl.LoadFont
rl_LoadFontEx            :: rl.LoadFontEx
rl_LoadFontFromImage     :: rl.LoadFontFromImage
rl_LoadFontFromMemory    :: rl.LoadFontFromMemory
rl_LoadFontData          :: rl.LoadFontData
rl_GenImageFontAtlas     :: rl.GenImageFontAtlas
rl_UnloadFontData        :: rl.UnloadFontData
rl_UnloadFont            :: rl.UnloadFont
rl_ExportFontAsCode      :: rl.ExportFontAsCode

rl_DrawFPS             :: rl.DrawFPS
rl_DrawText            :: rl.DrawText
rl_DrawTextEx          :: rl.DrawTextEx
rl_DrawTextPro         :: rl.DrawTextPro
rl_DrawTextCodepoint   :: rl.DrawTextCodepoint
rl_DrawTextCodepoints  :: rl.DrawTextCodepoints

rl_SetTextLineSpacing        :: rl.SetTextLineSpacing
rl_MeasureText               :: rl.MeasureText
rl_MeasureTextEx             :: rl.MeasureTextEx
rl_GetGlyphIndex             :: rl.GetGlyphIndex
rl_GetGlyphInfo              :: rl.GetGlyphInfo
rl_GetGlyphAtlasRec          :: rl.GetGlyphAtlasRec

rl_LoadUTF8              :: rl.LoadUTF8
rl_UnloadUTF8            :: rl.UnloadUTF8
rl_LoadCodepoints        :: rl.LoadCodepoints
rl_UnloadCodepoints      :: rl.UnloadCodepoints
rl_GetCodepointCount     :: rl.GetCodepointCount
rl_GetCodepoint          :: rl.GetCodepoint
rl_GetCodepointNext      :: rl.GetCodepointNext
rl_GetCodepointPrevious  :: rl.GetCodepointPrevious
rl_CodepointToUTF8       :: rl.CodepointToUTF8

rl_TextCopy                :: rl.TextCopy
rl_TextIsEqual             :: rl.TextIsEqual
rl_TextLength              :: rl.TextLength
rl_TextFormat              :: rl.TextFormat
rl_TextSubtext             :: rl.TextSubtext
rl_TextReplace             :: rl.TextReplace
rl_TextJoin                :: rl.TextJoin
rl_TextSplit               :: rl.TextSplit
rl_TextAppend              :: rl.TextAppend
rl_TextFindIndex           :: rl.TextFindIndex
rl_TextToUpper             :: rl.TextToUpper
rl_TextToLower             :: rl.TextToLower
rl_TextToPascal            :: rl.TextToPascal
rl_TextToInteger           :: rl.TextToInteger

rl_DrawLine3D            :: rl.DrawLine3D
rl_DrawPoint3D           :: rl.DrawPoint3D
rl_DrawCircle3D          :: rl.DrawCircle3D
rl_DrawTriangle3D        :: rl.DrawTriangle3D
rl_DrawTriangleStrip3D   :: rl.DrawTriangleStrip3D
rl_DrawCube              :: rl.DrawCube
rl_DrawCubeV             :: rl.DrawCubeV
rl_DrawCubeWires         :: rl.DrawCubeWires
rl_DrawCubeWiresV        :: rl.DrawCubeWiresV
rl_DrawSphere            :: rl.DrawSphere
rl_DrawSphereEx          :: rl.DrawSphereEx
rl_DrawSphereWires       :: rl.DrawSphereWires
rl_DrawCylinder          :: rl.DrawCylinder
rl_DrawCylinderEx        :: rl.DrawCylinderEx
rl_DrawCylinderWires     :: rl.DrawCylinderWires
rl_DrawCylinderWiresEx   :: rl.DrawCylinderWiresEx
rl_DrawCapsule           :: rl.DrawCapsule
rl_DrawCapsuleWires      :: rl.DrawCapsuleWires
rl_DrawPlane             :: rl.DrawPlane
rl_DrawRay               :: rl.DrawRay
rl_DrawGrid              :: rl.DrawGrid

rl_LoadModel              :: rl.LoadModel
rl_LoadModelFromMesh      :: rl.LoadModelFromMesh
rl_UnloadModel            :: rl.UnloadModel
rl_GetModelBoundingBox    :: rl.GetModelBoundingBox

rl_DrawModel              :: rl.DrawModel
rl_DrawModelEx            :: rl.DrawModelEx
rl_DrawModelWires         :: rl.DrawModelWires
rl_DrawModelWiresEx       :: rl.DrawModelWiresEx
rl_DrawBoundingBox        :: rl.DrawBoundingBox
rl_DrawBillboard          :: rl.DrawBillboard
rl_DrawBillboardRec       :: rl.DrawBillboardRec
rl_DrawBillboardPro       :: rl.DrawBillboardPro

rl_UploadMesh             :: rl.UploadMesh
rl_UpdateMeshBuffer       :: rl.UpdateMeshBuffer
rl_UnloadMesh             :: rl.UnloadMesh
rl_DrawMesh               :: rl.DrawMesh
rl_DrawMeshInstanced      :: rl.DrawMeshInstanced
rl_GetMeshBoundingBox     :: rl.GetMeshBoundingBox
rl_GenMeshTangents        :: rl.GenMeshTangents
rl_ExportMesh             :: rl.ExportMesh

rl_GenMeshPoly        :: rl.GenMeshPoly
rl_GenMeshPlane       :: rl.GenMeshPlane
rl_GenMeshCube        :: rl.GenMeshCube
rl_GenMeshSphere      :: rl.GenMeshSphere
rl_GenMeshHemiSphere  :: rl.GenMeshHemiSphere
rl_GenMeshCylinder    :: rl.GenMeshCylinder
rl_GenMeshCone        :: rl.GenMeshCone
rl_GenMeshTorus       :: rl.GenMeshTorus
rl_GenMeshKnot        :: rl.GenMeshKnot
rl_GenMeshHeightmap   :: rl.GenMeshHeightmap
rl_GenMeshCubicmap    :: rl.GenMeshCubicmap

rl_LoadMaterials        :: rl.LoadMaterials
rl_LoadMaterialDefault  :: rl.LoadMaterialDefault
rl_UnloadMaterial       :: rl.UnloadMaterial
rl_SetMaterialTexture   :: rl.SetMaterialTexture
rl_SetModelMeshMaterial :: rl.SetModelMeshMaterial

rl_LoadModelAnimations      :: rl.LoadModelAnimations
rl_UpdateModelAnimation     :: rl.UpdateModelAnimation
rl_UnloadModelAnimations    :: rl.UnloadModelAnimations
rl_IsModelAnimationValid    :: rl.IsModelAnimationValid

rl_CheckCollisionSpheres   :: rl.CheckCollisionSpheres
rl_CheckCollisionBoxes     :: rl.CheckCollisionBoxes
rl_CheckCollisionBoxSphere :: rl.CheckCollisionBoxSphere
rl_GetRayCollisionSphere   :: rl.GetRayCollisionSphere
rl_GetRayCollisionBox      :: rl.GetRayCollisionBox
rl_GetRayCollisionMesh     :: rl.GetRayCollisionMesh
rl_GetRayCollisionTriangle :: rl.GetRayCollisionTriangle
rl_GetRayCollisionQuad     :: rl.GetRayCollisionQuad

rl_InitAudioDevice   :: rl.InitAudioDevice
rl_CloseAudioDevice  :: rl.CloseAudioDevice
rl_IsAudioDeviceReady:: rl.IsAudioDeviceReady
rl_SetMasterVolume   :: rl.SetMasterVolume
rl_GetMasterVolume   :: rl.GetMasterVolume

rl_LoadWave            :: rl.LoadWave
rl_LoadWaveFromMemory  :: rl.LoadWaveFromMemory
rl_LoadSound           :: rl.LoadSound
rl_LoadSoundFromWave   :: rl.LoadSoundFromWave
rl_LoadSoundAlias      :: rl.LoadSoundAlias
rl_UpdateSound         :: rl.UpdateSound
rl_UnloadWave          :: rl.UnloadWave
rl_UnloadSound         :: rl.UnloadSound
rl_UnloadSoundAlias    :: rl.UnloadSoundAlias
rl_ExportWave          :: rl.ExportWave
rl_ExportWaveAsCode    :: rl.ExportWaveAsCode

rl_PlaySound       :: rl.PlaySound
rl_StopSound       :: rl.StopSound
rl_PauseSound      :: rl.PauseSound
rl_ResumeSound     :: rl.ResumeSound
rl_IsSoundPlaying  :: rl.IsSoundPlaying
rl_SetSoundVolume  :: rl.SetSoundVolume
rl_SetSoundPitch   :: rl.SetSoundPitch
rl_SetSoundPan     :: rl.SetSoundPan
rl_WaveCopy        :: rl.WaveCopy
rl_WaveCrop        :: rl.WaveCrop
rl_WaveFormat      :: rl.WaveFormat
rl_LoadWaveSamples :: rl.LoadWaveSamples
rl_UnloadWaveSamples :: rl.UnloadWaveSamples

rl_LoadMusicStream           :: rl.LoadMusicStream
rl_LoadMusicStreamFromMemory :: rl.LoadMusicStreamFromMemory
rl_UnloadMusicStream         :: rl.UnloadMusicStream
rl_PlayMusicStream           :: rl.PlayMusicStream
rl_IsMusicStreamPlaying      :: rl.IsMusicStreamPlaying
rl_UpdateMusicStream         :: rl.UpdateMusicStream
rl_StopMusicStream           :: rl.StopMusicStream
rl_PauseMusicStream          :: rl.PauseMusicStream
rl_ResumeMusicStream         :: rl.ResumeMusicStream
rl_SeekMusicStream           :: rl.SeekMusicStream
rl_SetMusicVolume            :: rl.SetMusicVolume
rl_SetMusicPitch             :: rl.SetMusicPitch
rl_SetMusicPan               :: rl.SetMusicPan
rl_GetMusicTimeLength        :: rl.GetMusicTimeLength
rl_GetMusicTimePlayed        :: rl.GetMusicTimePlayed

rl_LoadAudioStream              :: rl.LoadAudioStream
rl_UnloadAudioStream            :: rl.UnloadAudioStream
rl_UpdateAudioStream            :: rl.UpdateAudioStream
rl_IsAudioStreamProcessed       :: rl.IsAudioStreamProcessed
rl_PlayAudioStream              :: rl.PlayAudioStream
rl_PauseAudioStream             :: rl.PauseAudioStream
rl_ResumeAudioStream            :: rl.ResumeAudioStream
rl_IsAudioStreamPlaying         :: rl.IsAudioStreamPlaying
rl_StopAudioStream              :: rl.StopAudioStream
rl_SetAudioStreamVolume         :: rl.SetAudioStreamVolume
rl_SetAudioStreamPitch          :: rl.SetAudioStreamPitch
rl_SetAudioStreamPan            :: rl.SetAudioStreamPan
rl_SetAudioStreamBufferSizeDefault :: rl.SetAudioStreamBufferSizeDefault
rl_SetAudioStreamCallback       :: rl.SetAudioStreamCallback
rl_AttachAudioStreamProcessor   :: rl.AttachAudioStreamProcessor
rl_DetachAudioStreamProcessor   :: rl.DetachAudioStreamProcessor
rl_AttachAudioMixedProcessor    :: rl.AttachAudioMixedProcessor
rl_DetachAudioMixedProcessor    :: rl.DetachAudioMixedProcessor

rl_Vector2   :: rl.Vector2
rl_Vector3   :: rl.Vector3
rl_Vector4   :: rl.Vector4
rl_Matrix    :: rl.Matrix
rl_Color     :: rl.Color
rl_Rectangle :: rl.Rectangle

rl_Image         :: rl.Image
rl_Texture       :: rl.Texture
rl_RenderTexture :: rl.RenderTexture
rl_NPatchInfo    :: rl.NPatchInfo
rl_GlyphInfo     :: rl.GlyphInfo
rl_Font          :: rl.Font

rl_Camera3D :: rl.Camera3D
rl_Camera2D :: rl.Camera2D
rl_Camera   :: rl_Camera3D

rl_Mesh          :: rl.Mesh
rl_Shader        :: rl.Shader
rl_MaterialMap   :: rl.MaterialMap
rl_Material      :: rl.Material
rl_Transform     :: rl.Transform
rl_BoneInfo      :: rl.BoneInfo
rl_Model         :: rl.Model
rl_ModelAnimation:: rl.ModelAnimation

rl_Ray          :: rl.Ray
rl_RayCollision :: rl.RayCollision
rl_BoundingBox  :: rl.BoundingBox

rl_Wave        :: rl.Wave
rl_AudioStream :: rl.AudioStream
rl_Sound       :: rl.Sound
rl_Music       :: rl.Music

rl_VrDeviceInfo  :: rl.VrDeviceInfo
rl_VrStereoConfig:: rl.VrStereoConfig

rl_FilePathList        :: rl.FilePathList
rl_AutomationEvent     :: rl.AutomationEvent
rl_AutomationEventList :: rl.AutomationEventList

rl_ConfigFlag            :: rl.ConfigFlag
rl_ConfigFlags           :: rl.ConfigFlags

rl_TraceLogLevel         :: rl.TraceLogLevel
rl_KeyboardKey           :: rl.KeyboardKey
rl_MouseButton           :: rl.MouseButton
rl_MouseCursor           :: rl.MouseCursor
rl_GamepadButton         :: rl.GamepadButton
rl_GamepadAxis           :: rl.GamepadAxis

rl_MaterialMapIndex      :: rl.MaterialMapIndex
rl_ShaderLocationIndex   :: rl.ShaderLocationIndex
rl_ShaderUniformDataType :: rl.ShaderUniformDataType

rl_PixelFormat           :: rl.PixelFormat
rl_TextureFilter         :: rl.TextureFilter
rl_TextureWrap           :: rl.TextureWrap
rl_CubemapLayout         :: rl.CubemapLayout

rl_FontType              :: rl.FontType
rl_BlendMode             :: rl.BlendMode

rl_Gesture               :: rl.Gesture
rl_Gestures              :: rl.Gestures

rl_CameraMode            :: rl.CameraMode
rl_CameraProjection      :: rl.CameraProjection

rl_NPatchLayout          :: rl.NPatchLayout

rl_AudioCallback :: rl.AudioCallback

rl_LIGHTGRAY   :: rl.LIGHTGRAY
rl_GRAY        :: rl.GRAY
rl_DARKGRAY    :: rl.DARKGRAY
rl_YELLOW      :: rl.YELLOW
rl_GOLD        :: rl.GOLD
rl_ORANGE      :: rl.ORANGE
rl_PINK        :: rl.PINK
rl_RED         :: rl.RED
rl_MAROON      :: rl.MAROON
rl_GREEN       :: rl.GREEN
rl_LIME        :: rl.LIME
rl_DARKGREEN   :: rl.DARKGREEN
rl_SKYBLUE     :: rl.SKYBLUE
rl_BLUE        :: rl.BLUE
rl_DARKBLUE    :: rl.DARKBLUE
rl_PURPLE      :: rl.PURPLE
rl_VIOLET      :: rl.VIOLET
rl_DARKPURPLE  :: rl.DARKPURPLE
rl_BEIGE       :: rl.BEIGE
rl_BROWN       :: rl.BROWN
rl_DARKBROWN   :: rl.DARKBROWN
rl_WHITE       :: rl.WHITE
rl_BLACK       :: rl.BLACK
rl_BLANK       :: rl.BLANK
rl_MAGENTA     :: rl.MAGENTA
rl_RAYWHITE    :: rl.RAYWHITE

rl_rlMatrixMode   :: rl.rlMatrixMode
rl_rlPushMatrix   :: rl.rlPushMatrix
rl_rlPopMatrix    :: rl.rlPopMatrix
rl_rlLoadIdentity :: rl.rlLoadIdentity
rl_rlTranslatef   :: rl.rlTranslatef
rl_rlRotatef      :: rl.rlRotatef
rl_rlScalef       :: rl.rlScalef
rl_rlMultMatrixf  :: rl.rlMultMatrixf
rl_rlFrustum      :: rl.rlFrustum
rl_rlOrtho        :: rl.rlOrtho
rl_rlViewport     :: rl.rlViewport

rl_rlBegin        :: rl.rlBegin
rl_rlEnd          :: rl.rlEnd
rl_rlVertex2i     :: rl.rlVertex2i
rl_rlVertex2f     :: rl.rlVertex2f
rl_rlVertex3f     :: rl.rlVertex3f
rl_rlTexCoord2f   :: rl.rlTexCoord2f
rl_rlNormal3f     :: rl.rlNormal3f
rl_rlColor4ub     :: rl.rlColor4ub
rl_rlColor3f      :: rl.rlColor3f
rl_rlColor4f      :: rl.rlColor4f

rl_FramebufferAttachType :: rl.FramebufferAttachType
rl_FramebufferAttachTextureType :: rl.FramebufferAttachTextureType
rl_SetShaderValue :: rl.SetShaderValue
rl_GetShaderLocation :: rl.GetShaderLocation
rl_GetWorkingDirectory :: rl.GetWorkingDirectory
rl_SetShaderValueMatrix :: rl.SetShaderValueMatrix
rl_GetRandomValue :: rl.GetRandomValue
rl_LoadShaderFromMemory :: rl.LoadShaderFromMemory
rl_SetTraceLogLevel :: rl.SetTraceLogLevel
rl_GetMouseRay :: rl.GetMouseRay
rl_SetConfigFlags :: rl.SetConfigFlags
rl_LoadDirectoryFiles :: rl.LoadDirectoryFiles
rl_EaseLinearNone :: rl.EaseLinearNone
rl_DirectoryExists :: rl.DirectoryExists
rl_IsRenderTextureReady :: rl.IsRenderTextureReady
rl_UnloadDirectoryFiles :: rl.UnloadDirectoryFiles

rl_DEG2RAD :: rl.DEG2RAD
rl_RAD2DEG :: rl.RAD2DEG
rl_LoadShader   :: rl.LoadShader
rl_UnloadShader :: rl.UnloadShader
rl_MemAlloc     :: rl.MemAlloc
rl_GetFileName  :: rl.GetFileName

rl_rlEnableVertexArray          :: rl.rlEnableVertexArray
rl_rlDisableVertexArray         :: rl.rlDisableVertexArray
rl_rlEnableVertexBuffer         :: rl.rlEnableVertexBuffer
rl_rlDisableVertexBuffer        :: rl.rlDisableVertexBuffer
rl_rlEnableVertexBufferElement  :: rl.rlEnableVertexBufferElement
rl_rlDisableVertexBufferElement :: rl.rlDisableVertexBufferElement
rl_rlEnableVertexAttribute      :: rl.rlEnableVertexAttribute
rl_rlDisableVertexAttribute     :: rl.rlDisableVertexAttribute

rl_rlActiveTextureSlot     :: rl.rlActiveTextureSlot
rl_rlEnableTexture         :: rl.rlEnableTexture
rl_rlDisableTexture        :: rl.rlDisableTexture
rl_rlEnableTextureCubemap  :: rl.rlEnableTextureCubemap
rl_rlDisableTextureCubemap :: rl.rlDisableTextureCubemap
rl_rlTextureParameters     :: rl.rlTextureParameters
rl_rlCubemapParameters     :: rl.rlCubemapParameters

rl_rlEnableShader  :: rl.rlEnableShader
rl_rlDisableShader :: rl.rlDisableShader

rl_rlEnableFramebuffer  :: rl.rlEnableFramebuffer
rl_rlDisableFramebuffer :: rl.rlDisableFramebuffer
rl_rlActiveDrawBuffers  :: rl.rlActiveDrawBuffers
rl_rlBlitFramebuffer    :: rl.rlBlitFramebuffer

rl_rlDisableColorBlend      :: rl.rlDisableColorBlend
rl_rlEnableDepthTest        :: rl.rlEnableDepthTest
rl_rlDisableDepthTest       :: rl.rlDisableDepthTest
rl_rlEnableDepthMask        :: rl.rlEnableDepthMask
rl_rlDisableDepthMask       :: rl.rlDisableDepthMask
rl_rlEnableBackfaceCulling  :: rl.rlEnableBackfaceCulling
rl_rlDisableBackfaceCulling :: rl.rlDisableBackfaceCulling
rl_rlSetCullFace            :: rl.rlSetCullFace
rl_rlEnableScissorTest      :: rl.rlEnableScissorTest
rl_rlDisableScissorTest     :: rl.rlDisableScissorTest
rl_rlScissor                :: rl.rlScissor
rl_rlEnableWireMode         :: rl.rlEnableWireMode
rl_rlEnablePointMode        :: rl.rlEnablePointMode
rl_rlDisableWireMode        :: rl.rlDisableWireMode
rl_rlSetLineWidth           :: rl.rlSetLineWidth
rl_rlGetLineWidth           :: rl.rlGetLineWidth
rl_rlEnableSmoothLines      :: rl.rlEnableSmoothLines
rl_rlDisableSmoothLines     :: rl.rlDisableSmoothLines
rl_rlEnableStereoRender     :: rl.rlEnableStereoRender
rl_rlDisableStereoRender    :: rl.rlDisableStereoRender
rl_rlIsStereoRenderEnabled  :: rl.rlIsStereoRenderEnabled

rl_rlClearColor         :: rl.rlClearColor
rl_rlClearScreenBuffers :: rl.rlClearScreenBuffers
rl_rlCheckErrors        :: rl.rlCheckErrors
rl_rlSetBlendMode       :: rl.rlSetBlendMode
rl_rlSetBlendFactors    :: rl.rlSetBlendFactors
rl_rlSetBlendFactorsSeparate :: rl.rlSetBlendFactorsSeparate

rl_rlglInit  :: rl.rlglInit
rl_rlglClose :: rl.rlglClose
rl_rlLoadExtensions :: rl.rlLoadExtensions
rl_rlGetVersion     :: rl.rlGetVersion

rl_rlSetFramebufferWidth  :: rl.rlSetFramebufferWidth
rl_rlGetFramebufferWidth  :: rl.rlGetFramebufferWidth
rl_rlSetFramebufferHeight :: rl.rlSetFramebufferHeight
rl_rlGetFramebufferHeight :: rl.rlGetFramebufferHeight

rl_rlGetTextureIdDefault  :: rl.rlGetTextureIdDefault
rl_rlGetShaderIdDefault   :: rl.rlGetShaderIdDefault
rl_rlGetShaderLocsDefault :: rl.rlGetShaderLocsDefault

rl_rlLoadRenderBatch       :: rl.rlLoadRenderBatch
rl_rlUnloadRenderBatch     :: rl.rlUnloadRenderBatch
rl_rlDrawRenderBatch       :: rl.rlDrawRenderBatch
rl_rlSetRenderBatchActive  :: rl.rlSetRenderBatchActive
rl_rlDrawRenderBatchActive :: rl.rlDrawRenderBatchActive
rl_rlCheckRenderBatchLimit :: rl.rlCheckRenderBatchLimit
rl_rlSetTexture            :: rl.rlSetTexture

rl_rlLoadVertexArray                  :: rl.rlLoadVertexArray
rl_rlLoadVertexBuffer                 :: rl.rlLoadVertexBuffer
rl_rlLoadVertexBufferElement          :: rl.rlLoadVertexBufferElement
rl_rlUpdateVertexBuffer               :: rl.rlUpdateVertexBuffer
rl_rlUpdateVertexBufferElements       :: rl.rlUpdateVertexBufferElements
rl_rlUnloadVertexArray                :: rl.rlUnloadVertexArray
rl_rlUnloadVertexBuffer               :: rl.rlUnloadVertexBuffer
rl_rlSetVertexAttribute               :: rl.rlSetVertexAttribute
rl_rlSetVertexAttributeDivisor        :: rl.rlSetVertexAttributeDivisor
rl_rlSetVertexAttributeDefault        :: rl.rlSetVertexAttributeDefault
rl_rlDrawVertexArray                  :: rl.rlDrawVertexArray
rl_rlDrawVertexArrayElements          :: rl.rlDrawVertexArrayElements
rl_rlDrawVertexArrayInstanced         :: rl.rlDrawVertexArrayInstanced
rl_rlDrawVertexArrayElementsInstanced :: rl.rlDrawVertexArrayElementsInstanced

rl_rlLoadTexture         :: rl.rlLoadTexture
rl_rlLoadTextureDepth    :: rl.rlLoadTextureDepth
rl_rlLoadTextureCubemap  :: rl.rlLoadTextureCubemap
rl_rlUpdateTexture       :: rl.rlUpdateTexture
rl_rlGetGlTextureFormats :: rl.rlGetGlTextureFormats
rl_rlGetPixelFormatName  :: rl.rlGetPixelFormatName
rl_rlUnloadTexture       :: rl.rlUnloadTexture
rl_rlGenTextureMipmaps   :: rl.rlGenTextureMipmaps
rl_rlReadTexturePixels   :: rl.rlReadTexturePixels
rl_rlReadScreenPixels    :: rl.rlReadScreenPixels

rl_rlLoadFramebuffer     :: rl.rlLoadFramebuffer
rl_rlFramebufferAttach   :: rl.rlFramebufferAttach
rl_rlFramebufferComplete :: rl.rlFramebufferComplete
rl_rlUnloadFramebuffer   :: rl.rlUnloadFramebuffer

rl_rlLoadShaderCode      :: rl.rlLoadShaderCode
rl_rlCompileShader       :: rl.rlCompileShader
rl_rlLoadShaderProgram   :: rl.rlLoadShaderProgram
rl_rlUnloadShaderProgram :: rl.rlUnloadShaderProgram
rl_rlGetLocationUniform  :: rl.rlGetLocationUniform
rl_rlGetLocationAttrib   :: rl.rlGetLocationAttrib
rl_rlSetUniform          :: rl.rlSetUniform
rl_rlSetUniformMatrix    :: rl.rlSetUniformMatrix
rl_rlSetUniformSampler   :: rl.rlSetUniformSampler
rl_rlSetShader           :: rl.rlSetShader

rl_rlLoadComputeShaderProgram :: rl.rlLoadComputeShaderProgram
rl_rlComputeShaderDispatch    :: rl.rlComputeShaderDispatch

rl_rlLoadShaderBuffer    :: rl.rlLoadShaderBuffer
rl_rlUnloadShaderBuffer  :: rl.rlUnloadShaderBuffer
rl_rlUpdateShaderBuffer  :: rl.rlUpdateShaderBuffer
rl_rlBindShaderBuffer    :: rl.rlBindShaderBuffer
rl_rlReadShaderBuffer    :: rl.rlReadShaderBuffer
rl_rlCopyShaderBuffer    :: rl.rlCopyShaderBuffer
rl_rlGetShaderBufferSize :: rl.rlGetShaderBufferSize

rl_rlBindImageTexture :: rl.rlBindImageTexture

rl_rlGetMatrixModelview        :: rl.rlGetMatrixModelview
rl_rlGetMatrixProjection       :: rl.rlGetMatrixProjection
rl_rlGetMatrixTransform        :: rl.rlGetMatrixTransform
rl_rlGetMatrixProjectionStereo :: rl.rlGetMatrixProjectionStereo
rl_rlGetMatrixViewOffsetStereo :: rl.rlGetMatrixViewOffsetStereo
rl_rlSetMatrixProjection       :: rl.rlSetMatrixProjection
rl_rlSetMatrixModelview        :: rl.rlSetMatrixModelview
rl_rlSetMatrixProjectionStereo :: rl.rlSetMatrixProjectionStereo
rl_rlSetMatrixViewOffsetStereo :: rl.rlSetMatrixViewOffsetStereo

rl_rlLoadDrawCube :: rl.rlLoadDrawCube
rl_rlLoadDrawQuad :: rl.rlLoadDrawQuad

rl_RL_DEFAULT_BATCH_BUFFERS           :: rl.RL_DEFAULT_BATCH_BUFFERS
rl_RL_DEFAULT_BATCH_DRAWCALLS         :: rl.RL_DEFAULT_BATCH_DRAWCALLS
rl_RL_DEFAULT_BATCH_MAX_TEXTURE_UNITS :: rl.RL_DEFAULT_BATCH_MAX_TEXTURE_UNITS

rl_RL_MAX_MATRIX_STACK_SIZE           :: rl.RL_MAX_MATRIX_STACK_SIZE
rl_RL_MAX_SHADER_LOCATIONS            :: rl.RL_MAX_SHADER_LOCATIONS

rl_RL_CULL_DISTANCE_NEAR              :: rl.RL_CULL_DISTANCE_NEAR
rl_RL_CULL_DISTANCE_FAR               :: rl.RL_CULL_DISTANCE_FAR

rl_RL_TEXTURE_WRAP_S                  :: rl.RL_TEXTURE_WRAP_S
rl_RL_TEXTURE_WRAP_T                  :: rl.RL_TEXTURE_WRAP_T
rl_RL_TEXTURE_MAG_FILTER              :: rl.RL_TEXTURE_MAG_FILTER
rl_RL_TEXTURE_MIN_FILTER              :: rl.RL_TEXTURE_MIN_FILTER

rl_RL_TEXTURE_FILTER_NEAREST          :: rl.RL_TEXTURE_FILTER_NEAREST
rl_RL_TEXTURE_FILTER_LINEAR           :: rl.RL_TEXTURE_FILTER_LINEAR
rl_RL_TEXTURE_FILTER_MIP_NEAREST      :: rl.RL_TEXTURE_FILTER_MIP_NEAREST
rl_RL_TEXTURE_FILTER_NEAREST_MIP_LINEAR :: rl.RL_TEXTURE_FILTER_NEAREST_MIP_LINEAR
rl_RL_TEXTURE_FILTER_LINEAR_MIP_NEAREST :: rl.RL_TEXTURE_FILTER_LINEAR_MIP_NEAREST
rl_RL_TEXTURE_FILTER_MIP_LINEAR       :: rl.RL_TEXTURE_FILTER_MIP_LINEAR
rl_RL_TEXTURE_FILTER_ANISOTROPIC      :: rl.RL_TEXTURE_FILTER_ANISOTROPIC

rl_RL_TEXTURE_WRAP_REPEAT             :: rl.RL_TEXTURE_WRAP_REPEAT
rl_RL_TEXTURE_WRAP_CLAMP              :: rl.RL_TEXTURE_WRAP_CLAMP
rl_RL_TEXTURE_WRAP_MIRROR_REPEAT      :: rl.RL_TEXTURE_WRAP_MIRROR_REPEAT
rl_RL_TEXTURE_WRAP_MIRROR_CLAMP       :: rl.RL_TEXTURE_WRAP_MIRROR_CLAMP

rl_RL_MODELVIEW                       :: rl.RL_MODELVIEW
rl_RL_PROJECTION                      :: rl.RL_PROJECTION
rl_RL_TEXTURE                         :: rl.RL_TEXTURE

rl_RL_LINES                           :: rl.RL_LINES
rl_RL_TRIANGLES                       :: rl.RL_TRIANGLES
rl_RL_QUADS                           :: rl.RL_QUADS

rl_RL_UNSIGNED_BYTE                   :: rl.RL_UNSIGNED_BYTE
rl_RL_FLOAT                           :: rl.RL_FLOAT

rl_RL_STREAM_DRAW                     :: rl.RL_STREAM_DRAW
rl_RL_STREAM_READ                     :: rl.RL_STREAM_READ
rl_RL_STREAM_COPY                     :: rl.RL_STREAM_COPY
rl_RL_STATIC_DRAW                     :: rl.RL_STATIC_DRAW
rl_RL_STATIC_READ                     :: rl.RL_STATIC_READ
rl_RL_STATIC_COPY                     :: rl.RL_STATIC_COPY
rl_RL_DYNAMIC_DRAW                    :: rl.RL_DYNAMIC_DRAW
rl_RL_DYNAMIC_READ                    :: rl.RL_DYNAMIC_READ
rl_RL_DYNAMIC_COPY                    :: rl.RL_DYNAMIC_COPY

rl_RL_FRAGMENT_SHADER                 :: rl.RL_FRAGMENT_SHADER
rl_RL_VERTEX_SHADER                   :: rl.RL_VERTEX_SHADER
rl_RL_COMPUTE_SHADER                  :: rl.RL_COMPUTE_SHADER

rl_RL_ZERO                            :: rl.RL_ZERO
rl_RL_ONE                             :: rl.RL_ONE
rl_RL_SRC_COLOR                      :: rl.RL_SRC_COLOR
rl_RL_ONE_MINUS_SRC_COLOR            :: rl.RL_ONE_MINUS_SRC_COLOR
rl_RL_SRC_ALPHA                      :: rl.RL_SRC_ALPHA
rl_RL_ONE_MINUS_SRC_ALPHA            :: rl.RL_ONE_MINUS_SRC_ALPHA
rl_RL_DST_ALPHA                      :: rl.RL_DST_ALPHA
rl_RL_ONE_MINUS_DST_ALPHA            :: rl.RL_ONE_MINUS_DST_ALPHA
rl_RL_DST_COLOR                      :: rl.RL_DST_COLOR
rl_RL_ONE_MINUS_DST_COLOR            :: rl.RL_ONE_MINUS_DST_COLOR
rl_RL_SRC_ALPHA_SATURATE             :: rl.RL_SRC_ALPHA_SATURATE
rl_RL_CONSTANT_COLOR                 :: rl.RL_CONSTANT_COLOR
rl_RL_ONE_MINUS_CONSTANT_COLOR       :: rl.RL_ONE_MINUS_CONSTANT_COLOR
rl_RL_CONSTANT_ALPHA                 :: rl.RL_CONSTANT_ALPHA
rl_RL_ONE_MINUS_CONSTANT_ALPHA       :: rl.RL_ONE_MINUS_CONSTANT_ALPHA

rl_RL_FUNC_ADD                       :: rl.RL_FUNC_ADD
rl_RL_MIN                            :: rl.RL_MIN
rl_RL_MAX                            :: rl.RL_MAX
rl_RL_FUNC_SUBTRACT                 :: rl.RL_FUNC_SUBTRACT
rl_RL_FUNC_REVERSE_SUBTRACT         :: rl.RL_FUNC_REVERSE_SUBTRACT
rl_RL_BLEND_EQUATION                :: rl.RL_BLEND_EQUATION
rl_RL_BLEND_EQUATION_RGB            :: rl.RL_BLEND_EQUATION_RGB
rl_RL_BLEND_EQUATION_ALPHA          :: rl.RL_BLEND_EQUATION_ALPHA
rl_RL_BLEND_DST_RGB                 :: rl.RL_BLEND_DST_RGB
rl_RL_BLEND_SRC_RGB                 :: rl.RL_BLEND_SRC_RGB
rl_RL_BLEND_DST_ALPHA               :: rl.RL_BLEND_DST_ALPHA
rl_RL_BLEND_SRC_ALPHA               :: rl.RL_BLEND_SRC_ALPHA
rl_RL_BLEND_COLOR                   :: rl.RL_BLEND_COLOR

rl_Clamp       :: rl.Clamp
rl_Lerp        :: rl.Lerp
rl_Normalize   :: rl.Normalize
rl_Remap       :: rl.Remap
rl_Wrap        :: rl.Wrap
rl_FloatEquals :: rl.FloatEquals

rl_Vector2Transform       :: rl.Vector2Transform
rl_Vector2Rotate          :: rl.Vector2Rotate
rl_Vector2MoveTowards     :: rl.Vector2MoveTowards
rl_Vector2Clamp           :: rl.Vector2Clamp
rl_Vector2ClampValue      :: rl.Vector2ClampValue
rl_Vector2Equals          :: rl.Vector2Equals

rl_Vector3Project               :: rl.Vector3Project
rl_Vector3Reject                :: rl.Vector3Reject
rl_Vector3OrthoNormalize        :: rl.Vector3OrthoNormalize
rl_Vector3Transform             :: rl.Vector3Transform
rl_Vector3RotateByAxisAngle     :: rl.Vector3RotateByAxisAngle
rl_Vector3MoveTowards           :: rl.Vector3MoveTowards
rl_Vector3Barycenter            :: rl.Vector3Barycenter
rl_Vector3Unproject             :: rl.Vector3Unproject
rl_Vector3Clamp                 :: rl.Vector3Clamp
rl_Vector3ClampValue            :: rl.Vector3ClampValue
rl_Vector3Equals                :: rl.Vector3Equals

rl_MatrixTranslate       :: rl.MatrixTranslate
rl_MatrixRotate          :: rl.MatrixRotate
rl_MatrixRotateX         :: rl.MatrixRotateX
rl_MatrixRotateY         :: rl.MatrixRotateY
rl_MatrixRotateZ         :: rl.MatrixRotateZ
rl_MatrixRotateXYZ       :: rl.MatrixRotateXYZ
rl_MatrixRotateZYX       :: rl.MatrixRotateZYX
rl_MatrixScale           :: rl.MatrixScale
rl_MatrixPerspective     :: rl.MatrixPerspective
rl_MatrixOrtho           :: rl.MatrixOrtho
rl_MatrixLookAt          :: rl.MatrixLookAt
rl_MatrixToFloatV        :: rl.MatrixToFloatV
