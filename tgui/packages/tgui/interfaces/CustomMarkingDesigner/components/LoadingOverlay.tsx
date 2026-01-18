// ////////////////////////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star December 2025: Loading screen for the custom marking designer ///
// ////////////////////////////////////////////////////////////////////////////////////////////////

import type { SavingOverlayProps } from './SavingOverlay';
import { SavingOverlay } from './SavingOverlay';

export type LoadingOverlayProps = Omit<SavingOverlayProps, 'progress'>;

export const LoadingOverlay = ({
  title = 'Loading the designer…',
  subtitle = 'Preparing your canvas, previews, and layers. Hang tight!',
}: LoadingOverlayProps) => (
  <SavingOverlay title={title} subtitle={subtitle} progress={null} />
);
