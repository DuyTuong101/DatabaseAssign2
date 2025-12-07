"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.LogisticsService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
let LogisticsService = class LogisticsService {
    constructor(dataSource) {
        this.dataSource = dataSource;
    }
    async getRestaurants() {
        return this.dataSource.query('EXEC sp_GetListRestaurants');
    }
    async getFoodsByRestaurant(id) {
        return this.dataSource.query('EXEC sp_GetFoodsByRestaurant @RestaurantID = @0', [id]);
    }
    async createFullOrder(data) {
        const jsonItems = JSON.stringify(data.Items || []);
        try {
            const result = await this.dataSource.query(`EXEC sp_CreateFullOrder 
            @CustomerID = @0, 
            @PickupAddr = @1, 
            @DeliveryAddr = @2, 
            @CouponCode = @3, 
            @JsonItems = @4`, [
                data.CustomerID,
                data.PickupAddress,
                data.DeliveryAddress,
                data.CouponCode || null,
                jsonItems
            ]);
            return result[0];
        }
        catch (e) {
            throw new common_1.BadRequestException(e.message);
        }
    }
    async previewOrder(data) {
        const jsonItems = JSON.stringify(data.Items || []);
        try {
            const result = await this.dataSource.query(`EXEC sp_PreviewOrderBill @CouponCode = @0, @JsonItems = @1`, [data.CouponCode || null, jsonItems]);
            return result[0];
        }
        catch (e) {
            throw new common_1.BadRequestException(e.message);
        }
    }
    async getAllOrders(customerId) {
        return this.dataSource.query(`EXEC sp_GetAllOrders @CustomerID = @0`, [customerId]);
    }
    async getTrendingFoods(minQuantity) {
        return this.dataSource.query(`EXEC sp_GetTrendingFoods @MinQuantitySold = @0`, [minQuantity]);
    }
    async updateOrderInfo(orderId, address) {
        try {
            await this.dataSource.query(`EXEC sp_UpdateOrderInfo @OrderID = @0, @NewAddress = @1`, [orderId, address]);
            return { message: 'Cập nhật địa chỉ thành công!' };
        }
        catch (e) {
            throw new common_1.BadRequestException(e.message);
        }
    }
    async deleteOrder(orderId) {
        try {
            await this.dataSource.query(`EXEC sp_Order_Delete @OrderID = @0`, [orderId]);
            return { message: 'Đã xóa đơn hàng thành công!' };
        }
        catch (e) {
            throw new common_1.BadRequestException(e.message);
        }
    }
};
exports.LogisticsService = LogisticsService;
exports.LogisticsService = LogisticsService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectDataSource)()),
    __metadata("design:paramtypes", [typeorm_2.DataSource])
], LogisticsService);
//# sourceMappingURL=logistics.service.js.map