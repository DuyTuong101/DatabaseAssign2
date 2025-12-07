import { Injectable, BadRequestException } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';

@Injectable()
export class LogisticsService {
  constructor(@InjectDataSource() private dataSource: DataSource) {}

  // --- A. VIEW HELPERS ---
  async getRestaurants() {
    return this.dataSource.query('EXEC sp_GetListRestaurants');
  }

  async getFoodsByRestaurant(id: number) {
    return this.dataSource.query('EXEC sp_GetFoodsByRestaurant @RestaurantID = @0', [id]);
  }

  // --- B. ORDER FLOW ---
  async createFullOrder(data: any) {
    const jsonItems = JSON.stringify(data.Items || []);
    try {
      const result = await this.dataSource.query(
        `EXEC sp_CreateFullOrder 
            @CustomerID = @0, 
            @PickupAddr = @1, 
            @DeliveryAddr = @2, 
            @CouponCode = @3, 
            @JsonItems = @4`,
        [
          data.CustomerID,
          data.PickupAddress,
          data.DeliveryAddress,
          data.CouponCode || null,
          jsonItems
        ]
      );
      return result[0];
    } catch (e: any) { throw new BadRequestException(e.message); }
  }

  // [MỚI] TÍNH THỬ TIỀN (Preview)
  async previewOrder(data: any) {
    const jsonItems = JSON.stringify(data.Items || []);
    try {
      const result = await this.dataSource.query(
        `EXEC sp_PreviewOrderBill @CouponCode = @0, @JsonItems = @1`,
        [data.CouponCode || null, jsonItems]
      );
      return result[0];
    } catch (e: any) { throw new BadRequestException(e.message); }
  }

// Trong LogisticsService
  async getAllOrders(customerId: number) {
    // Gọi thủ tục sp_GetAllOrders mà chúng ta đã tạo trong SQL
    return this.dataSource.query(
      `EXEC sp_GetAllOrders @CustomerID = @0`, 
      [customerId]
    );
  }
  // Báo cáo Trending Foods
  async getTrendingFoods(minQuantity: number) {
    return this.dataSource.query(`EXEC sp_GetTrendingFoods @MinQuantitySold = @0`, [minQuantity]);
  }

  // Cập nhật địa chỉ đơn
async updateOrderInfo(orderId: number, address: string) {
    try {
      // Gọi thủ tục SQL đã tạo
      await this.dataSource.query(
        `EXEC sp_UpdateOrderInfo @OrderID = @0, @NewAddress = @1`,
        [orderId, address]
      );
      return { message: 'Cập nhật địa chỉ thành công!' };
    } catch (e: any) {
      throw new BadRequestException(e.message);
    }
  }

  // Hủy đơn
  async deleteOrder(orderId: number) {
    try {
      await this.dataSource.query(`EXEC sp_Order_Delete @OrderID = @0`, [orderId]);
      return { message: 'Đã xóa đơn hàng thành công!' };
    } catch (e: any) { throw new BadRequestException(e.message); }
  }
}