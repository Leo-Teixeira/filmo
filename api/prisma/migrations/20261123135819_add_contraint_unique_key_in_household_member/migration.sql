/*
  Warnings:

  - A unique constraint covering the columns `[userId,householdId]` on the table `HouseholdMember` will be added. If there are existing duplicate values, this will fail.

*/
-- CreateIndex
CREATE UNIQUE INDEX "HouseholdMember_userId_householdId_key" ON "HouseholdMember"("userId", "householdId");
