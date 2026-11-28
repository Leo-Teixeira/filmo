import { Module } from '@nestjs/common';
import { CollectionMemberController } from './collection-member.controller';
import { CollectionMemberGuard } from './collection-member.guard';
import { CollectionsController } from './collections.controller';
import { CollectionsService } from './collections.service';

@Module({
  controllers: [CollectionsController, CollectionMemberController],
  providers: [CollectionsService, CollectionMemberGuard],
})
export class CollectionsModule {}
