import { Inject, Injectable, Logger, NotFoundException } from "@nestjs/common";
import { PrismaService } from "../prisma/prisma.service";
import { METADATA_PROVIDER, MetadataProvider } from "../titles/interfaces/metadata-provider.interface";
import { CreateHouseholdDto } from "./dto/create-houshold-dto";
import { HouseholdRole } from "../generated/prisma/enums";
import { randomBytes } from "crypto";
import { isPrismaError, PrismaErrorCode } from "../prisma/prisma-errors";

@Injectable()
export class HouseholdService {
    constructor(private readonly prisma: PrismaService) {}

    async householdCollection(userId: string) {
        return this.prisma.household.findMany({
            where: { members: { some: { userId: userId } } },
            include: { collections: true, members: true },
            orderBy: { createdAt: 'asc' }
        });
    }

    async createHousehold(userId: string, dto: CreateHouseholdDto) {
        const name = dto.name != null ? dto.name : ''
        const inviteCode = randomBytes(6).toString('hex');
        try {
            return await this.prisma.$transaction(async (tx) => {
                const household = await tx.household.create({
                    data: { name: name, inviteCode: inviteCode }
                })
                const householdMember = await tx.householdMember.create({
                    data: { householdId: household.id, userId: userId, role: HouseholdRole.OWNER }
                })
            })
        } catch (error) {
            if (isPrismaError(error, PrismaErrorCode.ForeignKeyViolation)) {
                throw new HouseholdNotFoundException();
            }
        }
    }

    async deleteHousehold(userId: string, householdId: string) {
        try {
            return await this.prisma.household.delete({
                where: { id: householdId, members: {some: {userId: userId, role: "OWNER"}} },
                include: { members: true }
            })
        } catch (error) {
            if (isPrismaError(error, PrismaErrorCode.ForeignKeyViolation)) {
                throw new HouseholdNotFoundException();
            }
        }
    }

    async joinHousehold(userId: string, householdId: string) {
        try {
            return this.prisma.householdMember.create({
                data: {userId: userId, role: "MEMBER", householdId: householdId},
            })
        } catch (error) {
            if (isPrismaError(error, PrismaErrorCode.ForeignKeyViolation)) {
                throw new HouseholdNotFoundException();
            }
        }
    }

    async leaveHousehold(userId: string, householdId: string) {
        try {
            return this.prisma.householdMember.delete({
                where: { householdId_userId: {householdId: householdId, userId: userId} }
            })
        } catch (error) {
            if (isPrismaError(error, PrismaErrorCode.ForeignKeyViolation)) {
                throw new HouseholdNotFoundException();
            }
        }
    }
}

export class HouseholdNotFoundException extends NotFoundException {
    constructor() {
        super('Household not found');
    }
}