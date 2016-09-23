/*
Usage:		角色模型-不带描边
Author:		heweidong
History:	2014.10.20 创建
*/



Shader "Example/Character" {
	
	Properties { 
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_BumpMap("Bumpmap", 2D) = "bump" {}  
		_Ramp ("Shading Ramp", 2D) = "gray" {}
		_Color("Main Color",Color) = (1.0, 1.0, 1.0, 1.0)		// 水面倒影必须要的属性
		_AmbientColor ("环境光颜色", Color) = (0.1, 0.1, 0.1, 1.0)
		_SpecularColor ("高光颜色", Color) = (0.12, 0.31, 0.47, 1.0)
		_Glossiness ("高光强度", Range(1.0,512.0)) = 80.0
		//_RimColor ("边缘光颜色", Color) = (0.12, 0.31, 0.47, 1.0)
		//_RimPower ("边缘光强度", Range(0.5, 8.0)) = 3.0
		_Split1("──────────────────────────────────────────", Float) = 0.0
		_Illum ("自发光/高光控制贴图(R - 自发光 G - 高光)", 2D) = "black" {}
		_IllumEnable ("呼吸效果(0 -- 关闭, 1 -- 打开)", Float) = 0
		_IllumMin ("呼吸效果最小值", Range(-1.0, 0.5)) = -1
		_IllumMax ("呼吸效果最大值", Range(0.5, 1.5)) = 1
		_IllumSpeed ("呼吸效果速度", Range(0.2, 2.0)) = 1
		_IllumPower("自发光强度", Range(1.0, 3.0)) = 2.0
		_Split2("──────────────────────────────────────────", Float) = 0.0
		_AdjustMap("偏色贴图", 2D) = "black" {}
		_AdjustColor_R ("红通道控制颜色", Color) = (0.0, 0.0, 0.0, 1.0)
		_AdjustColor_G ("绿通道控制颜色", Color) = (0.0, 0.0, 0.0, 1.0)
		_AdjustColor_B ("蓝通道控制颜色", Color) = (0.0, 0.0, 0.0, 1.0)
		_AdjustColor_A ("A通道控制颜色", Color) = (0.0, 0.0, 0.0, 1.0)
		_AdjustContrastR("红通道对比强度", Range(0.1, 2.0)) = 1.0
		_AdjustContrastG("绿通道对比强度", Range(0.1, 2.0)) = 1.0
		_AdjustContrastB("蓝通道对比强度", Range(0.1, 2.0)) = 1.0
		_AdjustContrastA("A通道对比强度", Range(0.1, 2.0)) = 1.0
    } 

    SubShader { 
        Tags { "RenderType"="Opaque" "Queue" = "Transparent"}	// 保证在渲染队列的后方
		LOD 200
		
		CGPROGRAM
		#pragma surface surf CustomBlinnPhong exclude_path:prepass
		//#pragma "Lighting.cginc"
		#pragma target 3.0
		sampler2D _MainTex;
		sampler2D _BumpMap;
		sampler2D _Ramp;

		fixed4 _AmbientColor;
		fixed4 _SpecularColor;
		half _Glossiness;

		//fixed4 _RimColor;    
		//half _RimPower;

		half _IllumEnable;
		sampler2D _Illum;
		half _IllumPower;
		half _IllumMin;
		half _IllumMax;
		half _IllumSpeed;

		sampler2D _AdjustMap;
		fixed4 _AdjustColor_R;
		fixed4 _AdjustColor_G;
		fixed4 _AdjustColor_B;
		fixed4 _AdjustColor_A;
		half _AdjustContrastR;
		half _AdjustContrastG;
		half _AdjustContrastB;
		half _AdjustContrastA;

		const half IGNORE_GRAY = 0.05;
		
		struct SurfaceOutputEx {  
			half3 Albedo;
			half3 Normal;
			half3 Emission;
			half Specular;
			half Gloss;
			half Alpha;
			half _GlossEnable;
		};

		inline fixed4 LightingCustomBlinnPhong(SurfaceOutputEx s,fixed3 lightDir,fixed3 viewDir,fixed atten)
		{
		   fixed3 ambient = s.Albedo * _AmbientColor.rgb;
		   
		   fixed NdotL = saturate(dot(s.Normal,lightDir));
		   fixed diff = NdotL * 0.5 +0.5;
		   fixed3 ramp = tex2D(_Ramp, float2(diff,diff)).rgb;
		   fixed3 diffuse = s.Albedo *_LightColor0.rgb * ramp;
		   
		   fixed3 h = normalize(lightDir + viewDir);
		   float nh = saturate(dot(s.Normal,h));

			float specular = 0.0;
			float specPower = pow(nh, _Glossiness);
		   if (s._GlossEnable > 0)
		   {
			   specular = _LightColor0.rgb * specPower * atten * s._GlossEnable;
		   }
		   
		   fixed4 c;
		   c.rgb = (ambient + diffuse + specular * _SpecularColor)*(atten*2);
		   c.a = s.Alpha + (_LightColor0.a * _SpecularColor.a * specPower * atten);
		   return c;
		}
                    
		struct Input {
			float2 uv_MainTex;
			float2 uv_BumpMap;
			float2 uv_Illum;
			float2 uv_AdjustMap;
			half3 viewDir;
			
			float4 color : COLOR;
		};

		inline half3 ComputeIllum(float2 uv, half4 c, half3 e)
		{
			half illum_r = tex2D(_Illum, uv).r;
			if (_IllumEnable > 0.0)
			{
				if (illum_r > IGNORE_GRAY)
				{
					e.rgb += (c.rgb * illum_r * lerp(_IllumMin, _IllumMax, abs(sin(_Time.y * _IllumSpeed)))) * _IllumPower;
				}
			}
			else
			{
				e.rgb += (c.rgb * illum_r) * _IllumPower;
			}
			return e;
		}

		/*inline half ComputeGloss(float2 uv, half4 c, half3 specularColor)
		{
			half illum_g = tex2D(_Illum, uv).g;
			if (illum_g > IGNORE_GRAY)
			{
				return _Glossiness * illum_g;
			}
			return 0;
		}*/

		inline half3 ComputeAlbedo(float2 uv, half4 c)
		{ 
			half4 adj = tex2D (_AdjustMap, uv);
			half3 o = c.rgb;

			if (adj.r > IGNORE_GRAY)
			{
				//o = lerp(c.rgb, _AdjustColor_R.rgb, half3(adj.r, adj.r, adj.r) * _AdjustPowerR * _AdjustContrastR);
				float3 gg = (1.0,1.0,1.0);
				float3 noColor = (c.r + c.g +c.b)/3;
			    
				o = lerp(c.rgb,(noColor + _AdjustColor_R.rgb)*_AdjustContrastR, half3(adj.r, adj.r, adj.r));
			}
			else if (adj.g > IGNORE_GRAY)
			{
				float3 gg = (1.0,1.0,1.0);
				float3 noColor = (c.r + c.g +c.b)/3;
			    
				o = lerp(c.rgb,(noColor + _AdjustColor_G.rgb)*_AdjustContrastG, half3(adj.g, adj.g, adj.g));
			}
			else if (adj.b > IGNORE_GRAY)
			{
				float3 gg = (1.0,1.0,1.0);
				float3 noColor = (c.r + c.g +c.b)/3;
			    
				o = lerp(c.rgb,(noColor + _AdjustColor_B.rgb)*_AdjustContrastB, half3(adj.b, adj.b, adj.b));
			}
			else if (adj.a > IGNORE_GRAY)
			{
				float3 gg = (1.0,1.0,1.0);
				float3 noColor = (c.r + c.g +c.b)/3;
			    
				o = lerp(c.rgb,(noColor + _AdjustColor_A.rgb)*_AdjustContrastA, half3(adj.a, adj.a, adj.a));
			}
			return o;
		}

		void surf (Input IN, inout SurfaceOutputEx o) 
		{
			half4 c = tex2D (_MainTex, IN.uv_MainTex);
			o.Albedo = ComputeAlbedo(IN.uv_AdjustMap, c);
			o.Alpha = c.a;

			o.Normal = UnpackNormal(tex2D(_BumpMap,IN.uv_BumpMap));

			half3 e = half3(0, 0, 0);
			fixed rim = 1.0 - saturate(dot(normalize(IN.viewDir),o.Normal));
			//e.rgb = (_RimColor.rgb * pow(rim,_RimPower));

			half4 ca = half4(o.Albedo.rgb, c.a);

			half3 illum = ComputeIllum(IN.uv_Illum, ca, e);
			o.Emission = illum;

			o._GlossEnable = tex2D(_Illum, IN.uv_Illum).g; // 决定是否有高光效果
		}

		ENDCG
    } 
    Fallback "Diffuse" 
}  