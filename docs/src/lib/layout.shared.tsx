import type { BaseLayoutProps } from 'fumadocs-ui/layouts/shared';
import Image from 'next/image';

export function baseOptions(): BaseLayoutProps {
  return {
    nav: {
      title: (
        <>
          <Image
            src="/icon-rounded.png"
            width={24}
            height={24}
            alt="DistributeApp Logo"
            className="rounded-md"
          />
          <span className="font-medium">DistributeProject</span>
        </>
      ),
    },
  };
}
