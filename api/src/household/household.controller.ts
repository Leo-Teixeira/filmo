import { Body, Controller, Delete, Get, Param, ParseUUIDPipe, Patch, Post } from "@nestjs/common";
import { CurrentUser } from "../auth/current-user.decorator";
import type { JwtPayload } from "../auth/jwt-auth.guard";
import { CreateHouseholdDto } from "./dto/create-houshold-dto";
import { HouseholdService } from "./household.service";

@Controller('household')
export class HouseholdController {
    constructor(private readonly householdService: HouseholdService) {}

    @Get()
    householdCollection(@CurrentUser() user: JwtPayload) {
        return this.householdService.householdCollection(user.sub);
    }

    @Post()
    createHousehold(@CurrentUser() user: JwtPayload, @Body() dto: CreateHouseholdDto) {
        return this.householdService.createHousehold(user.sub, dto);
    }

    @Delete(':householdId')
    deleteHousehold(@CurrentUser() user: JwtPayload, @Param('householdId', ParseUUIDPipe) householdId: string) {
        return this.householdService.deleteHousehold(user.sub, householdId);
    }

    @Post(':inviteCode/join')
    joinHousehold(@CurrentUser() user: JwtPayload, @Param('inviteCode') inviteCode: string) {
        return this.householdService.joinHousehold(user.sub, inviteCode);
    }

    @Delete(':householdId/leave')
    leaveHousehold(@CurrentUser() user: JwtPayload, @Param('houseHoldId', ParseUUIDPipe) householdId: string) {
        return this.householdService.leaveHousehold(user.sub, householdId);
    }
}