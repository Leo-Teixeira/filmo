import { ConflictException, NotFoundException } from '@nestjs/common';

export class CollectionNotFoundException extends NotFoundException {
  constructor() {
    super('Collection not found');
  }
}

export class InviteCodeNotFoundException extends NotFoundException {
  constructor() {
    super('Invite code not found');
  }
}

export class CollectionItemNotFoundException extends NotFoundException {
  constructor() {
    super('Title not in this collection');
  }
}

export class AlreadyMemberException extends ConflictException {
  constructor() {
    super('Already a member of this collection');
  }
}

export class OwnerCannotLeaveException extends ConflictException {
  constructor() {
    super('The owner cannot leave; delete the collection instead');
  }
}

export class TitleAlreadyInCollectionException extends ConflictException {
  constructor() {
    super('Title already in this collection');
  }
}
