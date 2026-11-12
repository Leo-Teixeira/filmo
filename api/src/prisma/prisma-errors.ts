import { Prisma } from '../generated/prisma/client';

export const PrismaErrorCode = {
  UniqueConstraintViolation: 'P2002',
  RecordNotFound: 'P2025',
  // A relation points to a row that doesn't exist (e.g. a titleId that isn't in Title).
  ForeignKeyViolation: 'P2003',
} as const;

type PrismaErrorCode = (typeof PrismaErrorCode)[keyof typeof PrismaErrorCode];

export function isPrismaError(
  error: unknown,
  code: PrismaErrorCode,
): error is Prisma.PrismaClientKnownRequestError {
  return (
    error instanceof Prisma.PrismaClientKnownRequestError && error.code === code
  );
}
