const API = 'http://localhost:5000/api/logistics';

// --- 1. VIEW HELPERS ---
export const getListRestaurants = async () => {
  const r = await fetch(`${API}/restaurants`);
  if (!r.ok) throw new Error((await r.json()).message);
  return r.json();
};

export const getFoodsByRestaurant = async (restId: number) => {
  const r = await fetch(`${API}/restaurants/${restId}/foods`);
  if (!r.ok) throw new Error((await r.json()).message);
  return r.json();
};

// --- 2. ORDER FLOW ---
export const previewOrder = async (data: any) => {
  const r = await fetch(`${API}/orders/preview`, { 
    method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(data) 
  });
  if (!r.ok) throw new Error((await r.json()).message);
  return r.json();
};

export const createFullOrder = async (data: any) => {
  const r = await fetch(`${API}/orders`, { 
    method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(data) 
  });
  if (!r.ok) throw new Error((await r.json()).message);
  return r.json();
};

// --- 3. QUẢN LÝ ĐƠN HÀNG (Tracking & Action) ---

export const getAllOrders = async (customerId?: any) => {
  // Lấy danh sách đơn hàng (có lọc theo khách)
  let url = `${API}/orders`;
  if (customerId) url += `?customerId=${customerId}`;
  else url = `${API}/all-orders`; // Fallback nếu cần

  const r = await fetch(url);
  if (!r.ok) throw new Error((await r.json()).message);
  return r.json();
};

// [MỚI] Hàm sửa địa chỉ
export const updateAddress = async (id: number, address: string) => {
  const r = await fetch(`${API}/orders/${id}/info`, { 
    method: 'PUT', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ address }) 
  });
  if (!r.ok) throw new Error((await r.json()).message);
  return r.json();
};

// [MỚI] Hàm xóa đơn
export const deleteOrder = async (id: number) => {
  const r = await fetch(`${API}/orders/${id}`, { method: 'DELETE' });
  if (!r.ok) throw new Error((await r.json()).message);
  return r.json();
};

export const getTrendingFoods = async (min: number = 1) => {
  const r = await fetch(`${API}/trending?min=${min}`);
  if (!r.ok) throw new Error((await r.json()).message);
  return r.json();
};

export const updateStatus = async (id: number, status: string, driverId?: number) => {
  const r = await fetch(`${API}/orders/${id}`, { 
    method: 'PUT', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ status, driverId }) 
  });
  if (!r.ok) throw new Error((await r.json()).message);
  return r.json();
};

