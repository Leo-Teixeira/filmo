import { Prisma } from '../generated/prisma/client';

export const PrismaErrorCode = {
  UniqueConstraintViolation: 'P2002',
  RecordNotFound: 'P2025',
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
