import { ExecutionContext, UnauthorizedException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { JwtService } from '@nestjs/jwt';
import { AuthenticatedRequest, JwtAuthGuard } from './jwt-auth.guard';

const SECRET = 'test-secret-with-enough-length-for-hs256';

function contextFor(
  headers: Record<string, string>,
): [ExecutionContext, Partial<AuthenticatedRequest>] {
  const request = { headers } as Partial<AuthenticatedRequest>;
  const context = {
    getHandler: () => undefined,
    getClass: () => undefined,
    switchToHttp: () => ({ getRequest: () => request }),
  } as unknown as ExecutionContext;
  return [context, request];
}

describe('JwtAuthGuard', () => {
  const jwt = new JwtService({ secret: SECRET });
  const reflector = { getAllAndOverride: jest.fn() };
  const guard = new JwtAuthGuard(jwt, reflector as unknown as Reflector);

  beforeEach(() => reflector.getAllAndOverride.mockReturnValue(false));

  it('lets @Public() routes through without a token', async () => {
    reflector.getAllAndOverride.mockReturnValue(true);
    const [context] = contextFor({});

    await expect(guard.canActivate(context)).resolves.toBe(true);
  });

  it('rejects a request without Authorization header', async () => {
    const [context] = contextFor({});

    await expect(guard.canActivate(context)).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });

  it('rejects a non-Bearer scheme', async () => {
    const token = await jwt.signAsync({ sub: 'user-1' });
    const [context] = contextFor({ authorization: `Basic ${token}` });

    await expect(guard.canActivate(context)).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });

  it('rejects a token signed with another secret', async () => {
    const forged = await new JwtService({ secret: 'attacker' }).signAsync({
      sub: 'user-1',
    });
    const [context] = contextFor({ authorization: `Bearer ${forged}` });

    await expect(guard.canActivate(context)).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });

  it('rejects an expired token', async () => {
    const expired = await jwt.signAsync({ sub: 'user-1' }, { expiresIn: -10 });
    const [context] = contextFor({ authorization: `Bearer ${expired}` });

    await expect(guard.canActivate(context)).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });

  it('accepts a valid token and exposes the payload on request.user', async () => {
    const token = await jwt.signAsync({ sub: 'user-1' });
    const [context, request] = contextFor({ authorization: `Bearer ${token}` });

    await expect(guard.canActivate(context)).resolves.toBe(true);
    expect(request.user?.sub).toBe('user-1');
  });
});
