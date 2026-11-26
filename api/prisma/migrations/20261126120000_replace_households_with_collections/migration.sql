-- CreateEnum
CREATE TYPE "CollectionRole" AS ENUM ('OWNER', 'MEMBER');

-- DropForeignKey
ALTER TABLE "Collection" DROP CONSTRAINT "Collection_householdId_fkey";

-- DropForeignKey
ALTER TABLE "HouseholdMember" DROP CONSTRAINT "HouseholdMember_householdId_fkey";

-- DropForeignKey
ALTER TABLE "HouseholdMember" DROP CONSTRAINT "HouseholdMember_userId_fkey";

-- DropIndex
DROP INDEX "Collection_householdId_idx";

-- AlterTable
ALTER TABLE "Collection" DROP COLUMN "householdId",
ADD COLUMN     "inviteCode" TEXT NOT NULL;

-- DropTable
DROP TABLE "Household";

-- DropTable
DROP TABLE "HouseholdMember";

-- DropEnum
DROP TYPE "HouseholdRole";

-- CreateTable
CREATE TABLE "CollectionMember" (
    "collectionId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "role" "CollectionRole" NOT NULL DEFAULT 'MEMBER',
    "joinedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "CollectionMember_pkey" PRIMARY KEY ("collectionId","userId")
);

-- CreateIndex
CREATE INDEX "CollectionMember_userId_idx" ON "CollectionMember"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "Collection_inviteCode_key" ON "Collection"("inviteCode");

-- CreateIndex
CREATE INDEX "CollectionItem_titleId_idx" ON "CollectionItem"("titleId");

-- AddForeignKey
ALTER TABLE "CollectionMember" ADD CONSTRAINT "CollectionMember_collectionId_fkey" FOREIGN KEY ("collectionId") REFERENCES "Collection"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CollectionMember" ADD CONSTRAINT "CollectionMember_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

