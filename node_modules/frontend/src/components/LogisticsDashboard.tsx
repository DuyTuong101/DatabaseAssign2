import { useState, useEffect } from 'react';
import * as api from '../api/logistics';

export default function LogisticsDashboard() {
  const [tab, setTab] = useState('order');

  // ================= STATE: ORDER FLOW =================
  const [step, setStep] = useState(1);
  const [restaurants, setRestaurants] = useState<any[]>([]);
  const [foodList, setFoodList] = useState<any[]>([]);
  
  // Form Data
  const [customerID, setCustomerID] = useState('');
  const [selectedRest, setSelectedRest] = useState<any>(null);
  const [cart, setCart] = useState<any[]>([]);
  const [couponCode, setCouponCode] = useState('');
  const [deliveryAddr, setDeliveryAddr] = useState('Nhà riêng');

  // Pricing
  const [pricing, setPricing] = useState({ SubTotal: 0, Discount: 0, FinalTotal: 0, Message: '' });

  // ================= STATE: MY ORDERS (Nâng cấp) =================
  const [myOrders, setMyOrders] = useState<any[]>([]);
  const [editingId, setEditingId] = useState<number | null>(null); // ID đơn đang sửa địa chỉ
  const [newAddr, setNewAddr] = useState('');

  // ================= STATE: TRENDING =================
  const [trendingData, setTrendingData] = useState<any[]>([]);
  const [loading, setLoading] = useState(false); // Trạng thái tải trang

  // --- INITIAL LOAD ---
  useEffect(() => {
    setLoading(true);
    api.getListRestaurants()
       .then(setRestaurants)
       .catch(console.error)
       .finally(() => setLoading(false));
  }, []);

  // --- AUTO PREVIEW BILL ---
  useEffect(() => {
    if (cart.length > 0) {
        const payload = { CouponCode: couponCode, Items: cart.map(i => ({ FoodID: i.Food_ID, Quantity: i.Quantity })) };
        api.previewOrder(payload).then(res => {
            setPricing({ 
                SubTotal: res.SubTotal || 0, 
                Discount: res.Discount || 0, 
                FinalTotal: res.FinalTotal || 0,
                Message: res.Message || ''
            });
        }).catch(e => console.error(e));
    } else {
        setPricing({ SubTotal: 0, Discount: 0, FinalTotal: 0, Message: '' });
    }
  }, [cart, couponCode]);

  // ================= HANDLERS =================

  // --- ORDER FLOW ---
  const handleLogin = () => {
    if (!customerID) return alert('Vui lòng nhập ID Khách hàng');
    setStep(2);
  };

  const handleSelectRestaurant = async (rest: any) => {
    setSelectedRest(rest); 
    setDeliveryAddr('Nhà riêng');
    setLoading(true);
    try {
        const foods = await api.getFoodsByRestaurant(rest.RestaurantID);
        setFoodList(foods);
        setCart([]); setCouponCode(''); setStep(3);
    } catch (e) { console.error(e); }
    finally { setLoading(false); }
  };

  const addToCart = (food: any) => {
    const existing = cart.find(i => i.Food_ID === food.Food_ID);
    if (existing) {
      setCart(cart.map(i => i.Food_ID === food.Food_ID ? { ...i, Quantity: i.Quantity + 1 } : i));
    } else {
      setCart([...cart, { Food_ID: food.Food_ID, Name: food.Food_Name, Price: Number(food.Price), Quantity: 1 }]);
    }
  };

  const removeFromCart = (id: number) => setCart(cart.filter(i => i.Food_ID !== id));

  const handlePlaceOrder = async () => {
    if (cart.length === 0) return alert('Giỏ hàng trống');
    setLoading(true);
    try {
      const payload = {
        CustomerID: customerID, PickupAddress: selectedRest.Location, DeliveryAddress: deliveryAddr, CouponCode: couponCode,
        Items: cart.map(i => ({ FoodID: i.Food_ID, Quantity: i.Quantity }))
      };
      
      const res = await api.createFullOrder(payload);
      alert(`🎉 ĐẶT HÀNG THÀNH CÔNG!\nMã đơn: #${res.OrderID}\nThành tiền: ${Number(res.FinalTotal).toLocaleString()} VND`);
      
      // Chuyển tab & Load lại
      setTab('my_orders');
      loadMyOrders(customerID);
      
      // Reset
      setStep(1); setCart([]); setCustomerID(''); setSelectedRest(null);
    } catch (e: any) { alert(e.message); }
    finally { setLoading(false); }
  };

  // --- MY ORDERS HANDLERS ---
  const loadMyOrders = async (idInput?: string) => {
    const id = idInput || customerID;
    if (!id) return;
    setLoading(true);
    try {
        const res = await api.getAllOrders(id);
        setMyOrders(Array.isArray(res) ? res : []);
    } catch(e:any) { console.error(e); }
    finally { setLoading(false); }
  };

  // Hủy đơn hàng
  const handleCancelOrder = async (id: number) => {
    if(!confirm('Bạn có chắc muốn hủy đơn hàng này không?')) return;
    try {
        await api.deleteOrder(id);
        alert('✅ Đã hủy đơn hàng');
        loadMyOrders();
    } catch(e:any) { alert(e.message); }
  };

  // Cập nhật địa chỉ (Gọi trực tiếp API backend)
  const handleUpdateAddr = async (id: number) => {
    if(!newAddr) return alert('Vui lòng nhập địa chỉ mới');
    try {
        const res = await fetch(`http://localhost:5000/api/logistics/orders/${id}/info`, {
            method:'PUT', headers:{'Content-Type':'application/json'}, body:JSON.stringify({address:newAddr})
        });
        if(!res.ok) throw new Error((await res.json()).message);
        
        alert('✅ Cập nhật địa chỉ thành công');
        setEditingId(null);
        loadMyOrders();
    } catch(e:any) { alert(e.message); }
  };

  // --- TRENDING ---
  const handleGetTrending = async () => {
    setLoading(true);
    try { 
        const res = await api.getTrendingFoods(1); 
        setTrendingData(Array.isArray(res) ? res : []); 
    } catch(e:any) { alert(e.message); }
    finally { setLoading(false); }
  };

  // Helper UI
  const getRestLogo = (name: string) => `https://ui-avatars.com/api/?name=${encodeURIComponent(name)}&background=random&size=128`;

  return (
    <div style={{ fontFamily: "'Segoe UI', sans-serif", background: '#f8f9fa', minHeight: '100vh', padding: 20 }}>
      
      {/* HEADER TABS */}
      <div style={{ maxWidth: 1000, margin: '0 auto 25px', display: 'flex', gap: 12, justifyContent: 'center' }}>
        <button onClick={()=>setTab('order')} style={tab==='order'?activeBtn:btn}>🛍️ Đặt Hàng</button>
        <button onClick={()=>{setTab('my_orders'); if(customerID) loadMyOrders(customerID)}} style={tab==='my_orders'?activeBtn:btn}>📦 Đơn Của Tôi {customerID && `(#${customerID})`}</button>
        <button onClick={()=>{setTab('trending'); handleGetTrending()}} style={tab==='trending'?activeBtn:btn}>🔥 Món Hot</button>
      </div>

      {/* LOADING INDICATOR */}
      {loading && <div style={{textAlign:'center', padding:20, color:'#00B14F', fontWeight:'bold'}}>⏳ Đang tải dữ liệu...</div>}

      {/* === TAB 1: ORDER === */}
      {tab === 'order' && (
        <>
          {step===1 && (
            <div style={centerCard}>
                <h2 style={{color:'#00B14F', marginBottom:5}}>Xin chào!</h2>
                <p style={{color:'#666', marginBottom:20}}>Nhập mã khách hàng để bắt đầu</p>
                <input placeholder="Customer ID (VD: 41)" style={bigInput} value={customerID} onChange={e=>setCustomerID(e.target.value)}/>
                <button style={bigBtn} onClick={handleLogin}>Bắt đầu đặt món</button>
            </div>
          )}
          
          {step===2 && (
            <div style={{maxWidth: 1000, margin:'0 auto'}}>
                <button onClick={()=>setStep(1)} style={backBtn}>← Quay lại</button>
                <h3 style={{marginBottom:15}}>Chọn Nhà Hàng Gần Bạn</h3>
                <div style={grid}>
                    {restaurants.map(r=>(
                        <div key={r.RestaurantID} style={restCard} onClick={()=>handleSelectRestaurant(r)}>
                            <div style={{position:'relative', height:120}}>
                                <img src={r.Image_URL||getRestLogo(r.Name)} style={{width:'100%', height:'100%', objectFit:'cover'}} onError={(e:any)=>e.target.src=getRestLogo(r.Name)}/>
                                <div style={{position:'absolute', bottom:0, left:0, right:0, background:'linear-gradient(transparent, black)', padding:10, color:'white'}}>
                                    <b style={{fontSize:15}}>{r.Name}</b>
                                </div>
                            </div>
                            <div style={{padding:10, fontSize:13, color:'#555'}}>📍 {r.Location}</div>
                        </div>
                    ))}
                </div>
            </div>
          )}
          
          {step===3 && (
            <div style={{maxWidth: 1200, margin:'0 auto', display:'grid', gridTemplateColumns:'2fr 1fr', gap:25}}>
                {/* MENU */}
                <div>
                    <div style={{display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom:15}}>
                        <h3 style={{margin:0}}>Thực đơn: <span style={{color:'#00B14F'}}>{selectedRest?.Name}</span></h3>
                        <button onClick={()=>setStep(2)} style={backBtn}>Đổi quán</button>
                    </div>
                    <div style={grid}>
                        {foodList.map(f=>(
                            <div key={f.Food_ID} style={foodCard}>
                                <div style={{height:140, background:'#eee', overflow:'hidden'}}>
                                    {f.Image_URL ? <img src={f.Image_URL} style={{width:'100%', height:'100%', objectFit:'cover'}} onError={(e:any)=>e.target.style.display='none'}/> : <div style={{height:'100%',display:'flex',alignItems:'center',justifyContent:'center',fontSize:40}}>🍲</div>}
                                </div>
                                <div style={{padding:12}}>
                                    <div style={{fontWeight:'bold', fontSize:15, marginBottom:4}}>{f.Food_Name}</div>
                                    <div style={{color:'#00B14F', fontWeight:'bold', fontSize:14}}>{Number(f.Price).toLocaleString()} đ</div>
                                    <button onClick={()=>addToCart(f)} style={addBtn}>+ Thêm</button>
                                </div>
                            </div>
                        ))}
                    </div>
                </div>
                
                {/* CART */}
                <div>
                    <div style={cartPanel}>
                        <h3 style={{marginTop:0, borderBottom:'1px solid #eee', paddingBottom:15}}>🛒 Giỏ hàng ({cart.reduce((s,i)=>s+i.Quantity,0)})</h3>
                        
                        <div style={{maxHeight:300, overflowY:'auto'}}>
                            {cart.length===0 ? <p style={{textAlign:'center', color:'#999', padding:20}}>Giỏ hàng trống</p> : 
                                cart.map((i,x)=>(
                                    <div key={x} style={{display:'flex', justifyContent:'space-between', marginBottom:12, fontSize:14}}>
                                        <div>
                                            <div style={{fontWeight:'600'}}>{i.Name}</div>
                                            <div style={{fontSize:12, color:'#888'}}>x{i.Quantity}</div>
                                        </div>
                                        <div style={{display:'flex', alignItems:'center', gap:8}}>
                                            <b style={{color:'#333'}}>{(i.Price*i.Quantity).toLocaleString()}</b>
                                            <span onClick={()=>removeFromCart(i.Food_ID)} style={{color:'#ef4444', cursor:'pointer', fontSize:18}}>×</span>
                                        </div>
                                    </div>
                                ))
                            }
                        </div>

                        <div style={{borderTop:'2px dashed #eee', margin:'15px 0', paddingTop:15}}>
                            <input placeholder="Mã giảm giá..." value={couponCode} onChange={e=>setCouponCode(e.target.value)} style={{...input, marginBottom:10}}/>
                            {pricing.Message && <div style={{fontSize:12, marginBottom:10, color:pricing.Discount>0?'green':'red'}}>{pricing.Message}</div>}
                            
                            <div style={{display:'flex', justifyContent:'space-between', fontSize:14, marginBottom:5}}><span>Tạm tính:</span><b>{Number(pricing.SubTotal).toLocaleString()}</b></div>
                            <div style={{display:'flex', justifyContent:'space-between', fontSize:14, marginBottom:5, color:'green'}}><span>Giảm giá:</span><b>-{Number(pricing.Discount).toLocaleString()}</b></div>
                            <div style={{display:'flex', justifyContent:'space-between', fontSize:18, color:'#00B14F', fontWeight:'bold', marginTop:10}}><span>Tổng cộng:</span><b>{Number(pricing.FinalTotal).toLocaleString()} đ</b></div>
                        </div>
                        
                        <label style={{fontSize:12, fontWeight:'bold', display:'block', marginBottom:5}}>Giao tới:</label>
                        <input value={deliveryAddr} onChange={e=>setDeliveryAddr(e.target.value)} style={input} placeholder="Nhập địa chỉ..."/>
                        
                        <button onClick={handlePlaceOrder} style={checkoutBtn}>ĐẶT ĐƠN NGAY</button>
                    </div>
                </div>
            </div>
          )}
        </>
      )}

      {/* === TAB 2: MY ORDERS (Nâng cấp giao diện Card) === */}
      {tab === 'my_orders' && (
        <div style={{maxWidth: 800, margin:'0 auto'}}>
            <div style={{display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom:15}}>
                <h3 style={{margin:0, color: '#0d6efd'}}>📦 Đơn Hàng Của Bạn</h3>
                {!customerID && <p style={{color:'red', margin:0}}>Vui lòng nhập ID ở Tab 1 để xem.</p>}
            </div>

            {myOrders.length === 0 ? <div style={emptyState}>📭 Bạn chưa có đơn hàng nào.</div> :
             myOrders.map((o, i) => (
                <div key={i} style={orderCard}>
                    <div style={{display:'flex', justifyContent:'space-between', alignItems:'flex-start', marginBottom:15, paddingBottom:15, borderBottom:'1px solid #f0f0f0'}}>
                        <div>
                            <div style={{fontWeight:'bold', fontSize:16, color:'#333'}}>
                                {o.Restaurant_Name} <span style={{fontWeight:'normal', color:'#888', fontSize:14}}>(#{o.OrderID})</span>
                            </div>
                            <div style={{fontSize:13, color:'#666', marginTop:4}}>📅 {new Date(o.Order_Date).toLocaleString()}</div>
                        </div>
                        <span style={badgeStyle(o.Order_Status)}>{o.Order_Status}</span>
                    </div>

                    <div style={{display:'flex', justifyContent:'space-between', fontSize:14, marginBottom:15}}>
                        <div>
                            <div style={{color:'#666', marginBottom:2}}>Tài xế</div>
                            <div style={{fontWeight:'500'}}>{o.Driver_Name}</div>
                        </div>
                        <div style={{textAlign:'right'}}>
                            <div style={{color:'#666', marginBottom:2}}>Tổng tiền</div>
                            <div style={{color:'#00B14F', fontWeight:'bold', fontSize:16}}>{Number(o.Total_Amount).toLocaleString()} đ</div>
                        </div>
                    </div>

                    <div style={{background:'#f9fafb', padding:10, borderRadius:8, fontSize:13, display:'flex', justifyContent:'space-between', alignItems:'center'}}>
                        <div style={{flex:1}}>
                            📍 <b>Giao tới:</b> {editingId === o.OrderID ? (
                                <div style={{display:'flex', gap:5, marginTop:5}}>
                                    <input value={newAddr} onChange={e=>setNewAddr(e.target.value)} style={{...input, padding:5, marginBottom:0}}/>
                                    <button onClick={()=>handleUpdateAddr(o.OrderID)} style={{...btn, background:'#00B14F', color:'white', padding:'2px 10px'}}>Lưu</button>
                                    <button onClick={()=>setEditingId(null)} style={{...btn, padding:'2px 10px'}}>Hủy</button>
                                </div>
                            ) : (
                                <span> {o.Dropoff_Point || o.Delivery_Address}</span>
                            )}
                        </div>
                        {o.Order_Status === 'PENDING' && !editingId && (
                            <button onClick={()=>{setEditingId(o.OrderID); setNewAddr(o.Delivery_Address)}} style={{color:'#0d6efd', background:'none', border:'none', cursor:'pointer', fontWeight:'600'}}>Sửa</button>
                        )}
                    </div>

                    {/* Nút Hủy Đơn (Chỉ hiện khi PENDING) */}
                    {o.Order_Status === 'PENDING' && (
                        <div style={{marginTop:15, textAlign:'right'}}>
                            <button onClick={()=>handleCancelOrder(o.OrderID)} style={{...btn, background:'white', border:'1px solid #fee2e2', color:'#991b1b', fontSize:13}}>⛔ Hủy Đơn Hàng</button>
                        </div>
                    )}
                </div>
            ))}
        </div>
      )}

      {/* === TAB 3: TRENDING === */}
      {tab === 'trending' && (
        <div style={card}>
            <h3 style={{color:'#E64A19', marginTop:0, borderBottom:'2px solid #ffccbc', paddingBottom:10, display:'inline-block'}}>🔥 Top Món Ăn Bán Chạy</h3>
            <table style={{width:'100%', fontSize:14, borderCollapse:'collapse', marginTop:20}}>
                <thead>
                    <tr style={{textAlign:'left', color:'#666'}}>
                        <th style={{padding:10}}>Tên Món</th>
                        <th>Nhà Hàng</th>
                        <th style={{textAlign:'right'}}>Đã Bán</th>
                    </tr>
                </thead>
                <tbody>
                    {trendingData.map((t, i) => (
                        <tr key={i} style={{borderBottom:'1px solid #eee'}}>
                            <td style={{padding:15}}>
                                <div style={{fontWeight:'bold', color:'#333'}}>{t.Food_Name}</div>
                                <div style={{fontSize:12, color:'#888'}}>{t.Menu_Category}</div>
                            </td>
                            <td style={{color:'#555'}}>{t.Restaurant_Name}</td>
                            <td style={{textAlign:'right'}}>
                                <span style={{background:'#fff3e0', color:'#bf360c', padding:'5px 12px', borderRadius:20, fontWeight:'bold'}}>{t.Total_Quantity_Sold}</span>
                            </td>
                        </tr>
                    ))}
                    {trendingData.length === 0 && <tr><td colSpan={3} style={{padding:30, textAlign:'center', color:'#999'}}>Chưa có dữ liệu trending.</td></tr>}
                </tbody>
            </table>
        </div>
      )}
    </div>
  );
}

// Styles
const centerCard = { maxWidth: 400, margin:'80px auto', background:'white', padding:40, borderRadius:20, boxShadow:'0 10px 30px rgba(0,0,0,0.08)', textAlign:'center' as const };
const bigInput = { width:'100%', padding:14, fontSize:16, borderRadius:10, border:'1px solid #e5e7eb', marginBottom:20, boxSizing:'border-box' as const, outline:'none' };
const bigBtn = { width:'100%', padding:14, fontSize:16, background:'#00B14F', color:'white', border:'none', borderRadius:10, cursor:'pointer', fontWeight:'700', transition:'0.2s' };
const backBtn = { background:'none', border:'none', color:'#666', cursor:'pointer', marginBottom:15, fontSize:14, display:'flex', alignItems:'center', gap:5 };
const grid = { display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(200px, 1fr))', gap: '20px' };
const card = { border: '1px solid #e5e7eb', borderRadius: '16px', padding: '25px', background: '#fff', boxShadow: '0 4px 6px rgba(0,0,0,0.02)' };
const restCard = { ...card, padding: 0, overflow: 'hidden', cursor: 'pointer', transition: 'transform 0.2s', border:'none', boxShadow:'0 4px 15px rgba(0,0,0,0.08)' };
const foodCard = { ...card, padding: 0, overflow: 'hidden', display: 'flex', flexDirection: 'column' as const, border:'1px solid #eee', boxShadow:'none' };
const cartPanel = { background: 'white', padding: 25, borderRadius: 16, boxShadow: '0 10px 40px rgba(0,0,0,0.08)', position: 'sticky' as const, top: 20 };
const btn = { padding: '10px 20px', borderRadius: '10px', border: 'none', cursor: 'pointer', fontWeight: '600', background: '#fff', color: '#4b5563', transition:'0.2s' };
const primary = { ...btn, background: '#00B14F', color: 'white', boxShadow: '0 4px 10px rgba(0,177,79,0.2)' };
const activeBtn = { ...primary, transform: 'scale(1.05)' };
const addBtn = { background: '#e6f4ea', color: '#00B14F', border: '1px solid #00B14F', padding: '6px 15px', borderRadius: 20, cursor: 'pointer', fontWeight: 'bold', fontSize: 13, width: '100%', marginTop: 8 };
const checkoutBtn = { width: '100%', padding: 15, background: '#00B14F', color: 'white', border: 'none', borderRadius: 12, cursor: 'pointer', fontWeight: 'bold', fontSize: 16, marginTop: 15, boxShadow: '0 4px 15px rgba(0,177,79,0.3)' };
const input = { width: '100%', padding: '10px', borderRadius: '8px', border: '1px solid #ddd', marginBottom: '10px', boxSizing: 'border-box' as const, outline:'none' };
const badgeStyle = (s:string) => ({ padding:'5px 12px', borderRadius:20, fontSize:12, fontWeight:'bold', background: s==='COMPLETED'?'#dcfce7':s==='CANCELED'?'#fee2e2':s==='DELIVERING'?'#cff4fc':'#fff3cd', color: s==='COMPLETED'?'#166534':s==='CANCELED'?'#991b1b':s==='DELIVERING'?'#055160':'#854d0e' });
const orderCard = { background:'white', padding:20, borderRadius:16, marginBottom:20, boxShadow:'0 4px 12px rgba(0,0,0,0.05)', border:'1px solid #f0f0f0' };
const emptyState = { textAlign:'center' as const, padding:40, color:'#9ca3af', background:'white', borderRadius:16, border:'2px dashed #e5e7eb' };