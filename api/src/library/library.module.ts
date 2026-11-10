import { Module } from '@nestjs/common';
import { LibraryController } from './library.controller';
import { LibraryService } from './library.service';

// PrismaModule is @Global, so no import needed. TitlesModule isn't needed either:
// we only reuse the TitleNotFoundException class, not an injected service.
@Module({
  controllers: [LibraryController],
  providers: [LibraryService],
})
export class LibraryModule {}
