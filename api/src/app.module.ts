import { Module, ValidationPipe } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_PIPE } from '@nestjs/core';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AuthModule } from './auth/auth.module';
import { LibraryModule } from './library/library.module';
import { PrismaModule } from './prisma/prisma.module';
import { UserModule } from './user/user.module';
import { TitlesModule } from './titles/titles.module';
import { CollectionsModule } from './collections/collections.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, envFilePath: '../.env' }),
    PrismaModule,
    AuthModule,
    UserModule,
    TitlesModule,
    LibraryModule,
    CollectionsModule,
  ],
  controllers: [AppController],
  providers: [
    AppService,
    // Registered here rather than in main.ts so e2e tests run with the production pipe.
    {
      provide: APP_PIPE,
      useValue: new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    },
  ],
})
export class AppModule {}
