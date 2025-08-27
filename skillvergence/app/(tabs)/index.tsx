import { Platform } from "react-native";
import YoutubePlayer from "react-native-youtube-iframe";
import * as Speech from "expo-speech";
import Svg, { Line, Circle, Text as SvgText } from "react-native-svg";
import React, {useState} from "react";
import {View, Text, StyleSheet, ScrollView, Pressable, TextInput} from "react-native";

export default function Home() {
  const [tab, setTab] = useState<"video"|"podcast"|"map">("video");
  const [query, setQuery] = useState("");

  return (
    <View style={s.root}>
      {/* Header */}
      <View style={s.header}>
        <View style={s.brandDot} />
        <Text style={s.title}>EV Transition Coach</Text>
        <Text style={s.badge}>{greet()}</Text>
      </View>

      <ScrollView contentContainerStyle={s.body}>
        {/* Coach + KPIs */}
        <Card>
          <View style={s.row}>
            <Text style={s.emoji}>🤖</Text>
            <View style={{flex:1}}>
              <Text style={s.bold}>Coach Nova • personalized</Text>
              <Text style={s.muted}>Simple first, with shop analogies.</Text>
            </View>
            <Button text="Fast‑Track 20m" onPress={()=>{}} />
          </View>

          <View style={s.kpis}>
            <KPI label="Streak" value="3d" />
            <KPI label="Time" value="15m" />
            <KPI label="Confidence" value="72%" />
          </View>

          <Chips items={["Simple","Balanced","Pro"]} active={0} />
        </Card>

        {/* Canvas Tabs */}
        <View style={s.tabs}>
          {(["video","podcast","map"] as const).map(t=>(
            <Pressable key={t} onPress={()=>setTab(t)} style={[s.tab, tab===t && s.tabActive]}>
              <Text style={[s.tabText, tab===t && s.tabTextActive]}>
                {t==="video"?"Video":t==="podcast"?"Podcast":"Mind‑Map"}
              </Text>
            </Pressable>
          ))}
        </View>

        {/* CANVAS */}
        <Card>
          {tab==="video" && <VideoMock/>}
          {tab==="podcast" && <PodcastMock/>}
          {tab==="map" && <MapMock/>}
        </Card>
      </ScrollView>

      {/* Chat area */}
      <View style={s.chat}>
        <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={{gap:8}}>
          <Quick text="Compare alternator vs DC‑DC" onPress={()=>setQuery("Compare alternator vs DC‑DC")} />
          <Quick text="Explain DC fast charging simply" onPress={()=>setQuery("Explain DC fast charging simply")} />
          <Quick text="What PPE do I need?" onPress={()=>setQuery("What PPE do I need for HV work?")} />
        </ScrollView>
        <View style={s.askRow}>
          <View style={s.input}><Text style={{fontSize:18,marginRight:8}}>💬</Text>
            <TextInput value={query} onChangeText={setQuery} placeholder="Ask about this content…" placeholderTextColor="#aab7d4" style={{flex:1,color:"#e9f0ff"}}/>
          </View>
          <Button text="Ask Nova" onPress={()=>{}} />
        </View>
      </View>
    </View>
  );
}

/* --- Canvas mocks (no extra libs) --- */


function VideoMock(){
  return (
    <View>
      <Text style={s.h2}>Quick Overview (Video)</Text>
      <Text style={s.muted}>Start here; switch to podcast or map anytime.</Text>

      {/* Video player */}
      {Platform.OS === "web" ? (
        <iframe
          style={{width:"100%",height:220,border:0,borderRadius:12}}
          src={`https://www.youtube.com/embed/j9Ms-CfPjLY`}
          allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
          allowFullScreen
        />
      ) : (
        <YoutubePlayer height={220} play={false} videoId="j9Ms-CfPjLY" />
      )}

      <Chips items={["▶ EV Basics (7:42)","Charging 101 (6:18)"]} active={0}/>
      <Button
  text="🎧 Generate podcast from this video"
  onPress={()=> Speech.speak(
    "This will generate a podcast personalized to you",
    {rate:0.98,pitch:1.0,language:"en-US"}
  )}
/>
    </View>
  );
}

function PodcastMock(){
  return (
    <View>
      <Text style={s.h2}>Notebook‑style Podcast</Text>
      <Text style={s.muted}>Auto summary with definitions; offline‑ready in v2.</Text>
      <Bullet>HV safety: boundaries, PPE, lockout‑tagout</Bullet>
      <Bullet>Batteries: why DC‑DC replaces alternator</Bullet>
      <Bullet>Charging: AC vs DC; connectors; shop scenarios</Bullet>
      <View style={{flexDirection:"row",gap:10,marginTop:8}}>
        <Button text="Play (TTS)" onPress={()=>{}} />
        <Button text="Save for offline" onPress={()=>{}} />
      </View>
    </View>
  );
}
function MapMock(){
  return (
 <View style={{backgroundColor:"#0c1736",borderRadius:12,padding:8}}>
  <Svg width="100%" height={220} viewBox="0 0 320 220">
    <Line x1="60" y1="60" x2="155" y2="110" stroke="#2e4a8f" strokeWidth="2"/>
    <Line x1="155" y1="110" x2="240" y2="70"  stroke="#2e4a8f" strokeWidth="2"/>
    <Line x1="155" y1="110" x2="230" y2="165" stroke="#2e4a8f" strokeWidth="2"/>
    <Line x1="155" y1="110" x2="80"  y2="165" stroke="#2e4a8f" strokeWidth="2"/>

    <Circle cx="155" cy="110" r="26" fill="#274b9d"/>
    <SvgText x="155" y="114" fontSize="10" textAnchor="middle" fill="#e9f0ff">DC‑DC</SvgText>

    {[
      {x:60,y:60,t:"HV\nSafety"},
      {x:240,y:70,t:"BMS"},
      {x:230,y:165,t:"Charging"},
      {x:80,y:165,t:"Motors"}
    ].map((n,i)=>(
      <React.Fragment key={i}>
        <Circle cx={n.x} cy={n.y} r="22" fill="#1b2d63" />
        <SvgText x={n.x} y={n.y+34} fontSize="10" textAnchor="middle" fill="#aab7d4">{n.t}</SvgText>
      </React.Fragment>
    ))}
  </Svg>
</View>
  );
}

/* --- Small bits --- */

const Quick = ({text, onPress}:{text:string; onPress:()=>void}) => (
  <Pressable onPress={onPress} style={s.quick}>
    <Text style={s.quickTxt}>{text}</Text>
  </Pressable>
);

const Card = ({children}:{children:React.ReactNode}) => <View style={s.card}>{children}</View>;
const Button = ({text,onPress}:{text:string;onPress:()=>void}) => (
  <Pressable onPress={onPress} style={({pressed})=>[s.btn, pressed&&{opacity:.9,transform:[{scale:.98}]}]}>
    <Text style={s.btnTxt}>{text}</Text>
  </Pressable>
);
const KPI = ({label,value}:{label:string;value:string}) => (
  <View style={s.kpi}><Text style={s.kpiLabel}>{label}</Text><Text style={s.kpiVal}>{value}</Text></View>
);
const Chips = ({items,active}:{items:string[];active?:number}) => (
  <View style={s.chips}>{items.map((t,i)=>(
    <View key={i} style={[s.chip, active===i && {backgroundColor:"#22356e"}]}>
      <Text style={s.chipText}>{t}</Text>
    </View>
  ))}</View>
);
const Bullet = ({children}:{children:React.ReactNode}) => (
  <View style={{flexDirection:"row",gap:8,marginTop:6}}>
    <Text style={{color:"#e9f0ff"}}>•</Text><Text style={{color:"#e9f0ff"}}>{children}</Text>
  </View>
);

const greet=()=>{const h=new Date().getHours();return h<12?"Good morning":h<18?"Good afternoon":"Good evening"};

/* --- Styles --- */
const s = StyleSheet.create({
  root:{flex:1,backgroundColor:"#0b1020"},
  header:{flexDirection:"row",alignItems:"center",gap:10, padding:12},
  brandDot:{width:12,height:12,borderRadius:6,backgroundColor:"#78f39b"},
  title:{color:"#e9f0ff",fontSize:18,flex:1,fontWeight:"700"},
  
quick:{backgroundColor:"#1b2447",paddingHorizontal:10,paddingVertical:6,
      borderRadius:999,marginBottom:6,borderWidth:1,borderColor:"rgba(255,255,255,.05)"},
  quickTxt:{color:"#aab7d4",fontSize:12},

  badge:{backgroundColor:"#1b2447",color:"#aab7d4",paddingHorizontal:10,paddingVertical:6,borderRadius:999},
  body:{padding:12,gap:12},
  card:{backgroundColor:"#0f1630cc",borderRadius:16,padding:12,borderWidth:1,borderColor:"rgba(255,255,255,0.06)",gap:8},
  row:{flexDirection:"row",alignItems:"center",gap:10},
  emoji:{fontSize:28},
  bold:{color:"#e9f0ff",fontWeight:"700"}, muted:{color:"#aab7d4"},
  kpis:{flexDirection:"row",gap:10},
  kpi:{flex:1,backgroundColor:"#121a33",borderRadius:12,padding:10,borderWidth:1,borderColor:"rgba(255,255,255,0.06)"},
  kpiLabel:{color:"#aab7d4",fontSize:12}, kpiVal:{color:"#e9f0ff",fontSize:18,fontWeight:"700"},
  tabs:{flexDirection:"row",gap:8,paddingHorizontal:12},
  tab:{flex:1,backgroundColor:"#13204a",borderRadius:12,paddingVertical:10,alignItems:"center"},
  tabActive:{backgroundColor:"#22356e"}, tabText:{color:"#aab7d4",fontWeight:"700"}, tabTextActive:{color:"#e9f0ff"},
  chips:{flexDirection:"row",flexWrap:"wrap",gap:8}, chip:{backgroundColor:"#1b2447",paddingHorizontal:10,paddingVertical:6,borderRadius:999,borderWidth:1,borderColor:"rgba(255,255,255,0.05)"},
  chipText:{color:"#aab7d4",fontSize:12},
  btn:{backgroundColor:"#1f2a4f",borderRadius:12,paddingVertical:10,paddingHorizontal:12,borderWidth:1,borderColor:"rgba(255,255,255,0.12)"},
  btnTxt:{color:"#e9f0ff",fontWeight:"700"},
  chat:{padding:12,borderTopWidth:1,borderTopColor:"rgba(255,255,255,.06)",backgroundColor:"#0c1530cc"},
  askRow:{flexDirection:"row",gap:10,marginTop:8,alignItems:"center"},
  input:{flex:1,flexDirection:"row",alignItems:"center",backgroundColor:"#121a33",borderWidth:1,borderColor:"rgba(255,255,255,.08)",borderRadius:12,padding:10},
  h2:{color:"#e9f0ff",fontSize:16,marginBottom:4},
  videoBox:{height:220,backgroundColor:"#0c1736",borderRadius:12,alignItems:"center",justifyContent:"center"},
  videoTxt:{color:"#cfe1ff"},
  mapBox:{height:220,backgroundColor:"#0c1736",borderRadius:12,marginTop:6},
  node:{position:"absolute",width:78,height:62,borderRadius:31,backgroundColor:"#1b2d63",alignItems:"center",justifyContent:"center"},
  nodeCenter:{position:"absolute",left:110,top:80,width:90,height:70,borderRadius:40,backgroundColor:"#274b9d",alignItems:"center",justifyContent:"center"},
  nodeTxt:{color:"#e9f0ff",textAlign:"center",fontSize:12},
  line:{position:"absolute",height:2,backgroundColor:"#2e4a8f"},
});

