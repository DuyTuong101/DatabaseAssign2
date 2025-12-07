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
exports.LogisticsController = void 0;
const common_1 = require("@nestjs/common");
const logistics_service_1 = require("./logistics.service");
let LogisticsController = class LogisticsController {
    constructor(srv) {
        this.srv = srv;
    }
    getRestaurants() { return this.srv.getRestaurants(); }
    getFoods(id) { return this.srv.getFoodsByRestaurant(+id); }
    previewOrder(body) { return this.srv.previewOrder(body); }
    createOrder(body) { return this.srv.createFullOrder(body); }
    getAllOrders(id) {
        if (!id)
            return [];
        return this.srv.getAllOrders(+id);
    }
    getTrending(min) { return this.srv.getTrendingFoods(Number(min) || 1); }
    updateOrderInfo(id, body) {
        return this.srv.updateOrderInfo(+id, body.address);
    }
    deleteOrder(id) { return this.srv.deleteOrder(+id); }
};
exports.LogisticsController = LogisticsController;
__decorate([
    (0, common_1.Get)('restaurants'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], LogisticsController.prototype, "getRestaurants", null);
__decorate([
    (0, common_1.Get)('restaurants/:id/foods'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], LogisticsController.prototype, "getFoods", null);
__decorate([
    (0, common_1.Post)('orders/preview'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], LogisticsController.prototype, "previewOrder", null);
__decorate([
    (0, common_1.Post)('orders'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], LogisticsController.prototype, "createOrder", null);
__decorate([
    (0, common_1.Get)('orders'),
    __param(0, (0, common_1.Query)('customerId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], LogisticsController.prototype, "getAllOrders", null);
__decorate([
    (0, common_1.Get)('trending'),
    __param(0, (0, common_1.Query)('min')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], LogisticsController.prototype, "getTrending", null);
__decorate([
    (0, common_1.Put)('orders/:id/info'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", void 0)
], LogisticsController.prototype, "updateOrderInfo", null);
__decorate([
    (0, common_1.Delete)('orders/:id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], LogisticsController.prototype, "deleteOrder", null);
exports.LogisticsController = LogisticsController = __decorate([
    (0, common_1.Controller)('logistics'),
    __metadata("design:paramtypes", [logistics_service_1.LogisticsService])
], LogisticsController);
//# sourceMappingURL=logistics.controller.js.map