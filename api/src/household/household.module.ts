import { Module } from "@nestjs/common";
import { METADATA_PROVIDER } from "../titles/interfaces/metadata-provider.interface";
import { TmdbProvider } from "../titles/tmdb/tmdb.provider";
import { HttpModule } from "@nestjs/axios";
import { ConfigService } from "@nestjs/config";
import { HouseholdController } from "./household.controller";
import { HouseholdService } from "./household.service";

@Module({
    imports: [
        HttpModule.registerAsync({
            inject: [ConfigService],
            useFactory: (config: ConfigService) => ({
                baseURL: config.getOrThrow<string>('TMDB_BASE_URL'),
                timeout: 5000,
                headers: {
                    Auhtorization: `Bearer ${config.getOrThrow<string>('TMDB_ACCESS_TOKEN')}`,
                },
            }),
        }),
    ],
    controllers: [HouseholdController],
    providers: [HouseholdService],
})

export class HouseholdModule {}