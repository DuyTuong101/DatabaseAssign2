import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import * as path from 'path';

// --- IMPORT CÁC MODULE CHỨC NĂNG ---
// 1. Module Logistics (Mới - Chứa User, History, Revenue)
import { LogisticsModule } from './logistics/logistics.module'; 
@Module({
  imports: [
    // 1. Cấu hình biến môi trường
    ConfigModule.forRoot({ 
      isGlobal: true, 
      envFilePath: [
        path.resolve(__dirname, '../../config/config.env'),
        path.resolve(__dirname, '../config/config.env'),
        'config.env'
      ] 
    }),

    // 2. Cấu hình Database
    TypeOrmModule.forRoot({
      type: 'mssql',
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT ?? '1433', 10),
      username: process.env.DB_USERNAME || 'trace_user',
      password: process.env.DB_PASSWORD || 'Trace@12345678',
      database: process.env.DB_NAME || 'LOGISTICSDATABASE',
      
      synchronize: false,
      autoLoadEntities: true, // Tự động nhận diện các bảng (Entities)
      options: { encrypt: false, trustServerCertificate: true },
    }),

    // 3. Nạp các Module chức năng vào hệ thống\
    LogisticsModule, // <--- BẮT BUỘC PHẢI CÓ DÒNG NÀY
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}