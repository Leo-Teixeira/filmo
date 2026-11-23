import { IsString } from "class-validator";

export class CreateHouseholdDto {
    @IsString()
    name?: string;
}