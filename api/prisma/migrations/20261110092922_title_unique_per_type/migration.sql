/*
  Warnings:

  - A unique constraint covering the columns `[provider,type,externalId]` on the table `Title` will be added. If there are existing duplicate values, this will fail.

*/
-- DropIndex
DROP INDEX "Title_provider_externalId_key";

-- CreateIndex
CREATE UNIQUE INDEX "Title_provider_type_externalId_key" ON "Title"("provider", "type", "externalId");
