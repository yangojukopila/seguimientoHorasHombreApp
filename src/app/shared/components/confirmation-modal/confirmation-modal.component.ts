import { Component, EventEmitter, Input, Output, HostListener } from '@angular/core';
import { CommonModule } from '@angular/common';
import { trigger, state, style, transition, animate } from '@angular/animations';

@Component({
  selector: 'app-confirmation-modal',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './confirmation-modal.component.html',
  styleUrl: './confirmation-modal.component.scss',
  animations: [
    trigger('fadeIn', [
      transition(':enter', [
        style({ opacity: 0 }),
        animate('200ms ease-in', style({ opacity: 1 }))
      ]),
      transition(':leave', [
        animate('200ms ease-out', style({ opacity: 0 }))
      ])
    ]),
    trigger('slideIn', [
      transition(':enter', [
        style({ transform: 'translateY(-20px)', opacity: 0 }),
        animate('300ms ease-out', style({ transform: 'translateY(0)', opacity: 1 }))
      ]),
      transition(':leave', [
        animate('200ms ease-in', style({ transform: 'translateY(-20px)', opacity: 0 }))
      ])
    ])
  ]
})
export class ConfirmationModalComponent {
  @Input() title: string = '¿Confirmar acción?';
  @Input() message: string = '¿Está seguro que desea continuar?';
  @Input() confirmText: string = 'Confirmar';
  @Input() cancelText: string = 'Cancelar';
  @Input() isVisible: boolean = false;
  
  @Output() onConfirm = new EventEmitter<void>();
  @Output() onCancel = new EventEmitter<void>();

  @HostListener('document:keydown.escape', ['$event'])
  handleEscapeKey(event: KeyboardEvent) {
    if (this.isVisible) {
      this.cancel();
    }
  }

  @HostListener('document:keydown.enter', ['$event'])
  handleEnterKey(event: KeyboardEvent) {
    if (this.isVisible) {
      event.preventDefault();
      this.confirm();
    }
  }

  confirm() {
    this.onConfirm.emit();
  }

  cancel() {
    this.onCancel.emit();
  }

  onBackdropClick(event: MouseEvent) {
    // Only close if clicking directly on backdrop, not its children
    if (event.target === event.currentTarget) {
      this.cancel();
    }
  }
}
