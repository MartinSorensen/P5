﻿Shader "Custom/RiverShader"
{
	Properties
	{
		_MainColor("Main Color", Color) = (0.5,0.5,0.5,1.0)
		_Normal1("Normal Map one", 2D) = "white" {}
		_Normal2("Normal Map two", 2D) = "white" {}
		_FoamColor("Foam Color", Color) = (1.0,1.0,1.0,1.0)
		_FoamAmount("Foam amount", Range(0.0,10.0)) = 1.0
		_ReflectionAmount("Reflection Amount", Range(0.0,1.0)) = 0.5
		[HideInInspector]_ReflectionTex("Internal reflection", 2D) = "white" {}
	}
		SubShader
	{
		Tags{ "Queue" = "Transparent" "RenderType" = "Transparent" }
		LOD 100

		Pass
	{
		Blend SrcAlpha OneMinusSrcAlpha

		CGPROGRAM
#pragma vertex vert
#pragma fragment frag
		// make fog work
#pragma multi_compile_fog

#include "UnityCG.cginc"



	struct v2f
	{
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
		float4 screenPos : TEXCOORD1;
		float2 normal1 : TEXCOORD2;
		float2 normal2 : TEXCOORD3;
		float3	TtoW0 	 : TEXCOORD4;
		float3	TtoW1	 : TEXCOORD5;
		float3	TtoW2	 : TEXCOORD6;
		UNITY_FOG_COORDS(1)
	};

	sampler2D _MainTex;
	float4 _MainTex_ST, _Normal1_ST, _Normal2_ST;
	sampler2D _ReflectionTex;

	v2f vert(appdata_tan v)
	{
		v2f o;
		o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
		o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
		o.screenPos = ComputeScreenPos(o.pos);

		o.normal1 = TRANSFORM_TEX(v.texcoord, _Normal1);
		o.normal2 = TRANSFORM_TEX(v.texcoord, _Normal2);

		float3 worldNormal = UnityObjectToWorldNormal(v.normal);
		float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);

		//Get the world binormal/bitangent of the vertex
		float3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;
		o.TtoW0 = float3(worldTangent.x, worldBinormal.x, worldNormal.x);
		o.TtoW1 = float3(worldTangent.y, worldBinormal.y, worldNormal.y);
		o.TtoW2 = float3(worldTangent.z, worldBinormal.z, worldNormal.z);

		UNITY_TRANSFER_FOG(o,o.vertex);
		return o;
	}

	half4 _MainColor;
	half4 _FoamColor;
	float _FoamAmount;
	sampler2D _CameraDepthTexture;
	sampler2D _Normal1;
	sampler2D _Normal2;
	float _ReflectionAmount;


	fixed4 frag(v2f i) : SV_Target
	{

	//Distortion
	float phase = _Time[1] / 20.0;
	float f = frac(phase);
	fixed3 normal = UnpackNormal(tex2D(_Normal1, i.normal1 * frac(phase + 0.5)));
	fixed3 normal2 = UnpackNormal(tex2D(_Normal2, i.normal2 * f));
	if (f > 0.5f)
		f = 2.0f * (1.0f - f);
	else
		f = 2.0f * f;
	// transform normal to the world space


	fixed4 finalColor = 1.0;
	half4 screenWithOffset = i.screenPos + lerp(float4(normal,0.0), float4(normal2,0.0), f);
	half4 rtReflections = tex2Dproj(_ReflectionTex, UNITY_PROJ_COORD(screenWithOffset));
	finalColor.rgb = lerp(_MainColor.rgb, rtReflections.rgb, _ReflectionAmount);
	//Foam
	float sceneZ = LinearEyeDepth(tex2Dproj(_CameraDepthTexture,UNITY_PROJ_COORD(i.screenPos)).r);
	float diff = (abs(sceneZ - i.screenPos.z)) / _FoamAmount;
	if (diff <= 1.0f) {
		finalColor = _FoamColor;
	}

	UNITY_APPLY_FOG(i.fogCoord, col);
	return finalColor;
	}
		ENDCG
	}
	}
}
