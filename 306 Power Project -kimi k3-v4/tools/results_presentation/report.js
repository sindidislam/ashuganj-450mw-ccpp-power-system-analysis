'use strict';
const DATA=JSON.parse(document.getElementById('report-data').textContent);
const tableState=new Map();
const htmlEscape=x=>String(x??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
function nice(x){return String(x).replace(/_/g,' ').replace(/\bMVA r\b/g,'MVAr');}
function format(x){
 if(x===null||x===undefined||x==='NaN'||x==='nan'||x==='')return '<span class="legend">—</span>';
 if(typeof x==='number'){if(!Number.isFinite(x))return '—';if(Number.isInteger(x))return String(x);return Math.abs(x)>0&&Math.abs(x)<.0001?x.toExponential(3):x.toLocaleString('en-US',{maximumFractionDigits:5});}
 const s=String(x), key=s.toUpperCase();
 if(/^(PASS|OK|VERIFIED|CONVERGED)$/.test(key))return '<span class="badge good">'+htmlEscape(s)+'</span>';
 if(/^(FAIL|FAILED|NOT_DETECTABLE|NO_TRIP)$/.test(key))return '<span class="badge bad">'+htmlEscape(s)+'</span>';
 if(s.length<55&&/ASSUMPT|QUALIFIED|UNRESOLVED|NOT.DETERMINABLE|LIMITED/.test(key))return '<span class="badge warn">'+htmlEscape(s)+'</span>';
 return htmlEscape(s);
}
function setTab(id){
 if(!document.getElementById(id))id='overview';
 for(const section of document.querySelectorAll('.section'))section.hidden=section.id!==id;
 for(const btn of document.querySelectorAll('.nav button')){btn.classList.toggle('active',btn.dataset.tab===id);btn.setAttribute('aria-selected',btn.dataset.tab===id);}
 history.replaceState(null,'','#'+id);window.scrollTo({top:0,behavior:'instant'});
}
function drawTable(key){
 const state=tableState.get(key), t=state.table;
 const query=(document.querySelector('#'+state.section+' .section-filter')?.value||'').toLowerCase().trim();
 const filtered=t.rows.filter(r=>!query||Object.values(r).join(' ').toLowerCase().includes(query));
 const pages=Math.max(1,Math.ceil(filtered.length/10));state.page=Math.min(state.page,pages-1);
 const rows=filtered.slice(state.page*10,state.page*10+10);
 const node=document.getElementById(key);
 node.querySelector('tbody').innerHTML=rows.length?rows.map(r=>'<tr>'+t.columns.map(c=>'<td class="'+(typeof r[c]==='number'?'numeric':'')+'">'+format(r[c])+'</td>').join('')+'</tr>').join(''):'<tr><td colspan="'+t.columns.length+'" class="empty">No rows match this case or search.</td></tr>';
 node.querySelector('.row-count').textContent=filtered.length+' matching rows / '+t.rows.length+' total · page '+(state.page+1)+' of '+pages;
 node.querySelector('.prev').disabled=state.page===0;node.querySelector('.next').disabled=state.page>=pages-1;
}
function createSection(id,section){
 const node=document.getElementById(id);if(!section)return;
 node.innerHTML='<p class="eyebrow">'+htmlEscape(section.label||id)+'</p><h1>'+htmlEscape(section.title)+'</h1><p class="lead">'+htmlEscape(section.intro||'')+'</p>';
 if(id==='emergency')node.innerHTML+='<div class="flow"><div><h3>01 · Generator disconnected</h3><small>Grid supply is checked through the modeled transformer path. Generator P and Q are zero.</small></div><div><h3>02 · AC supply lost</h3><small>Battery/DC service is assessed for the represented controls and trip loads.</small></div><div><h3>03 · Emergency diesel supply</h3><small>Available plant evidence sets the limits of any diesel or UPS supply claim.</small></div></div>';
 if(section.highlights)node.innerHTML+='<div class="cards">'+section.highlights.map(c=>'<div class="card"><div class="kicker">'+htmlEscape(c.label)+'</div><div class="big">'+htmlEscape(c.value)+'</div><p>'+htmlEscape(c.note||'')+'</p></div>').join('')+'</div>';
 const notes=section.notes||[];
 if(notes.length)node.innerHTML+='<div class="note"><p>'+htmlEscape(notes[0])+'</p></div>';
 if(section.figures?.length){
  node.innerHTML+='<h2>Comparisons and measured response</h2><div class="figure-grid">'+section.figures.map(f=>'<figure class="figure wide"><div class="figure-top"><h3>'+htmlEscape(f.title)+'</h3><a href="'+htmlEscape(f.path)+'" target="_blank">Open figure ↗</a></div><a href="'+htmlEscape(f.path)+'" target="_blank"><img src="'+htmlEscape(f.path)+'" alt="'+htmlEscape(f.title)+'" loading="lazy"></a><figcaption>'+htmlEscape(f.caption||'')+'</figcaption></figure>').join('')+'</div>';
 }
 node.innerHTML+='<h2>Case tables and evidence</h2><div class="section-tools"><label for="'+id+'-filter">Find a case</label><input class="section-filter" id="'+id+'-filter" placeholder="Type a case ID, fault location, relay or status…" aria-label="Filter all '+htmlEscape(id)+' tables"><button class="outline clear-filter">Clear</button></div><p class="legend">All exported rows are available below and in the full CSV downloads. Scroll wide tables horizontally. A dash means unavailable or not applicable; it does not mean zero.</p>';
 for(const [index,t] of (section.tables||[]).entries()){
  const key=id+'-table-'+index;
  const table=document.createElement('div');table.className='table-card';table.id=key;
  table.innerHTML='<div class="table-head"><h3>'+htmlEscape(t.title)+'</h3>'+(t.csv?'<a href="'+htmlEscape(t.csv)+'" download>Full CSV ↓</a>':'')+'</div>'+(t.caption?'<p class="table-caption">'+htmlEscape(t.caption)+'</p>':'')+'<div class="scroll"><table><thead><tr>'+t.columns.map(c=>'<th>'+htmlEscape(nice(c))+'</th>').join('')+'</tr></thead><tbody></tbody></table></div><div class="table-footer"><span class="row-count"></span><div><button class="prev" aria-label="Previous table page">←</button><button class="next" aria-label="Next table page">→</button></div></div>';
  node.appendChild(table);tableState.set(key,{table:t,page:0,section:id});
  table.querySelector('.prev').onclick=()=>{tableState.get(key).page--;drawTable(key);};
  table.querySelector('.next').onclick=()=>{tableState.get(key).page++;drawTable(key);};drawTable(key);
 }
 if(notes.length>1)node.innerHTML+='<h2>Interpretation and limits</h2><ul class="note-list">'+notes.slice(1).map(n=>'<li>'+htmlEscape(n)+'</li>').join('')+'</ul>';
 // Reattach after final HTML addition, which recreates descendants.
 for(const [key,state] of tableState)if(state.section===id){const table=document.getElementById(key);table.querySelector('.prev').onclick=()=>{state.page--;drawTable(key);};table.querySelector('.next').onclick=()=>{state.page++;drawTable(key);};}
 const filter=node.querySelector('.section-filter');
 const update=()=>{for(const [key,state] of tableState)if(state.section===id){state.page=0;drawTable(key);}};
 filter.addEventListener('input',update);node.querySelector('.clear-filter').onclick=()=>{filter.value='';update();};
}
for(const id of ['emergency','phase4','phase5','phase6'])createSection(id,DATA[id]);
document.querySelectorAll('[data-tab]').forEach(b=>b.addEventListener('click',()=>setTab(b.dataset.tab)));
document.getElementById('print-report').onclick=()=>window.print();
setTab(location.hash.slice(1)||'overview');
